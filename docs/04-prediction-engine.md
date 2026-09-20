# Prediction Engine

Implemented in [`db/migrations/014_views_and_functions.sql`](../db/migrations/014_views_and_functions.sql)
and called from [`api/src/modules/prediction/`](../api/src/modules/prediction/).

## The one rule

**The engine never says a student will get in.** It reports how a rank compares
to published closing ranks from previous years. The `match_grade` enum has four
values and none of them is a promise:

| Grade                      | Meaning                                              |
| -------------------------- | ---------------------------------------------------- |
| `strong_historical_match`  | Better than even the strictest of the last few years |
| `historical_match`         | Within the recency-weighted closing rank             |
| `borderline`               | Just outside the most lenient year                   |
| `outside_historical_range` | Beyond the historical range                          |

Every response carries a `disclaimer` string, and the API returns it on every
prediction — not as an optional field the client may drop.

---

## Step 1 — collapse the history

`mv_program_cutoff_trend` reduces `cutoff_data` to one row per
`(authority, exam, program, seat_type, quota, gender)`:

- Per year, the **last published round** is the real closing rank.
- The five most recent years become fixed columns `closing_y0 .. closing_y4`,
  where `y0` is that **authority's** newest year.
- Also stored: `best_closing_rank` (strictest year), `worst_closing_rank`,
  `latest_closing_rank`, `years_available`, `trend_slope` (`regr_slope` of
  closing rank over year) and `cutoff_history` as JSONB.

Refreshed by `fn_refresh_cutoff_trend()` at the end of every published import.

## Step 2 — weight by recency

Design doc section 13. Weights come from `prediction_year_weights`:

```
offset 0 (newest)  0.40
offset 1           0.30
offset 2           0.20
offset 3           0.10
offset 4           0.00
```

`fn_weighted_rank()` drops missing years from **both** numerator and
denominator, so a program with two years of history is weighted correctly
rather than being pulled toward zero.

Worked example — a program with closing ranks 44,000 / 48,000 / 46,500 / 51,000:

```
plain average   = 47,375
weighted        = (44000*0.4 + 48000*0.3 + 46500*0.2 + 51000*0.1) / 1.0
                = 46,400
```

The weighted figure sits closer to the recent trend, which is the point.

## Step 3 — eligibility, not just rank

`fn_predict_colleges()` filters before it compares:

- **Seat types** — the candidate's own category **plus** the OPEN pool, because
  a reserved candidate is always also considered for OPEN seats. PwD variants
  only when `p_is_pwd`.
- **Genders** — via `genders.allowed_applicant_genders`, so a female candidate
  sees both the neutral and the female-only pool.
- **Quotas** — `HS` only where the college is in the candidate's home state,
  `OS` only where it is not, driven by the flags on `quotas`.

## Step 4 — grade and score

`fn_grade_match()` applies, in order:

```
rank <= best_closing  * strong_match_factor (0.90) and years >= 2  → strong
rank <= weighted_closing                                           → historical match
rank <= worst_closing * borderline_factor  (1.10)                  → borderline
otherwise                                                          → outside
```

Thresholds are per `prediction_weight_profiles` row, so an authority whose
cutoffs swing more can be graded more conservatively.

The 0–100 `score` is a logistic on `ln(weighted_closing / rank)` — equal ranks
give 50 — adjusted by:

| Signal                          | Effect |
| ------------------------------- | ------ |
| 3+ years of data                | +3     |
| fewer than 3 years              | −5     |
| home-state quota seat           | +4     |
| branch in the student's list    | +5     |
| state in the student's list     | +3     |
| cutoff tightening (slope < 0)   | −3     |

## Step 5 — snapshot

Results are written to `prediction_results` with the numbers as computed. The
trend view is refreshed whenever a new round is published, so without a snapshot
a student reopening a saved prediction would silently see different numbers than
the ones they screenshotted.

---

## Percentile input

`fn_percentile_to_rank()` resolves in strict order:

1. An **official** published pair for that exam / year / session / category.
2. Linear interpolation between the two nearest official pairs.
3. `appeared_candidates * (100 − percentile) / 100`, returned as a ±3% band.

Only step 1 sets `is_official = true`. Steps 2 and 3 must be labelled as
estimates in the UI; the API sets `rankIsEstimated` and `rankEstimateMethod` for
exactly this. If none of the three can produce an answer the function returns no
rows and the API asks the student for a rank instead of inventing one.

**Step 3 wants the right denominator.** It reads `exam_rank_data` with
`ORDER BY exam_session_id NULLS FIRST`, so it prefers the row with no session —
the all-sessions aggregate — and that is deliberate. A JEE Main rank is computed
across both sessions on unique candidates, so a single session's attendance is
the wrong number to divide by: Session 1 of 2026 saw about 13.0 lakh against
roughly 14.7 lakh unique overall, a 13% gap under a method that advertises a 3%
band. Load one row per exam-year with `exam_session_id = NULL`,
`category_id = NULL` and the unique merit-list count.

**Until that row exists, the input is switched off rather than left to fail.**
`/reference/bootstrap` reports `hasPercentileData` per exam, computed from the
same two tables step 1–3 read, and the form shows the Rank/Percentile toggle
only when it is true. `hasPercentile` alone says the exam reports a percentile,
which is not the same question — and answering the wrong one put a button on the
main screen that returned a 400 every time it was pressed.

---

## Marks input

BITS is the one authority so far that does not allot on a rank. It admits
directly off the BITSAT merit list and publishes a cut-off **score** per
programme, which inverts every comparison in the engine above: a higher number
is a better result.

That runs through a mirror of the stack rather than a flag on it —
`mv_program_score_trend`, `fn_weighted_score`, `fn_grade_score_match`,
`fn_predict_colleges_by_score`. Sharing one body would have meant a sign test on
the reach cut-off, on each of the three grade comparisons and on the ordering,
in a function the rank path's 327,965 rows already depend on.

Three things differ beyond the sign:

**Everything is compared in percent of the paper total.** BITSAT was marked out
of 450 through 2021 and out of 390 from 2022, so raw scores are not comparable
across that boundary — 306/450 and 226/390 are near enough the same standard
while the raw figures suggest a collapse. `cutoff_data.max_score` is therefore
mandatory alongside any `closing_score` (`chk_cutoff_score_needs_max`), and the
function converts back to the candidate's own total on the way out so every
figure it returns is in the units they typed.

**The grade factors divide instead of multiplying.** `strong_match_factor` 0.900
means "10% better than the strictest year" either way: `rank <= best * 0.9`, or
`pct >= toughest / 0.9`. One profile tunes both engines. The mirror breaks only
at the ceiling — a percentage stops at 100 where a rank has no floor — so the
strong threshold is clamped there, which at a 95% cut-off honestly reads as "a
perfect paper".

**The logistic is steeper: 12.0, against the rank path's 3.0.** Ranks span
orders of magnitude; a whole field of score cut-offs fits between 35% and 80% of
the paper. At 3.0 the entire BITSAT spread compresses into roughly 38–60 and
every programme looks alike.

`trend_slope` also changes meaning: percentage points of the paper per year, and
**positive** means tightening. The rank view's is places per year and negative
means tightening. `prediction_results` stores both kinds in the one column, and
which one a row carries is decided by whether it has a `closing_score`.

The API picks the engine from `exams.primary_score_type = 'marks'` and says
which it used in `measure`, so a client never has to guess which way "better"
points. Sending a rank to a marks-based exam is a 400, not a silent conversion.

---

## Tuning without a deploy

```sql
-- Weight the most recent year more heavily.
UPDATE prediction_year_weights w
SET weight = 0.50
FROM prediction_weight_profiles p
WHERE p.id = w.profile_id AND p.code = 'default' AND w.year_offset = 0;

-- Tighten the borderline band for one authority.
INSERT INTO prediction_weight_profiles
  (code, name, counselling_authority_id, is_active, borderline_factor)
SELECT 'comedk_tuned', 'COMEDK tuned', id, true, 1.05
FROM counselling_authorities WHERE code = 'COMEDK';
```
