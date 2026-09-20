# API Reference

Base URL: `/{API_PREFIX}/v{version}` — by default `/api/v1`.
Interactive docs (non-production only): `/docs`.

Every 2xx response is wrapped:

```json
{ "success": true, "data": { } }
```

Errors:

```json
{
  "success": false,
  "statusCode": 404,
  "path": "/api/v1/exams/NOPE",
  "timestamp": "2026-09-19T12:00:00.000Z",
  "error": { "message": "Unknown exam code: NOPE" }
}
```

| Status | Route | Notes |
| ------ | ----- | ----- |
| done | `POST /prediction` | Rank, percentile or score → historical matches |
| done | `POST /prediction/what-if` | Same profile at several hypothetical ranks or scores |
| done | `GET  /prediction/{requestId}` | Replay a stored prediction from its snapshot |
| done | `GET  /cutoffs/program/{id}` | Year-by-year opening/closing ranks |
| done | `GET  /cutoffs/program/{id}/trend` | Aggregated trend row for the chart |
| done | `GET  /reference/bootstrap` | Every lookup the predict form needs, in one call. Per exam: `hasPercentileData` and `usesMarks` decide which input the form asks for |
| done | `GET  /exams`, `/exams/{code}`, `/exams/{code}/schedule` | |
| done | `GET  /colleges`, `/colleges/{slug}` | Search and detail |
| done | `GET  /colleges/compare?slugs=` | Side-by-side at one seat dimension |
| done | `GET/POST /shortlist`, `/shortlist/ids`, `/shortlist/reorder` | Requires auth |
| done | `POST /auth/register`, `/auth/login`, `GET /auth/me` | |
| done | `GET/POST /admin/imports`, `/admin/imports/{id}/approve` | Admin role |
| todo | `GET  /calendar?from&to` | Month grid, backed by `v_exam_calendar` |
| todo | `GET  /branches`, `/branches/{code}` | |
| todo | `GET/PATCH /users/me`, `/users/me/scores` | |
| todo | `GET /notifications`, `PATCH /notifications/{id}/read` | |

---

## `POST /prediction`

Request:

```json
{
  "examCode": "JEE_MAIN",
  "academicYear": 2026,
  "rank": 45821,
  "categoryCode": "OBC_NCL",
  "gender": "male",
  "isPwd": false,
  "homeStateCode": "UP",
  "branchCodes": ["CSE", "IT", "ECE"],
  "stateCodes": ["UP", "DL"],
  "collegeTypes": ["NIT", "IIIT"],
  "limit": 200
}
```

Send `percentile` instead of `rank` for a percentile-based exam, or `score` (with
an optional `maxScore`) for a marks-based one. Exactly one of the three is
required, and `usesMarks` on the exam's `/reference/bootstrap` entry says which
the form should ask for. Sending a rank to a marks-based exam is a 400.

Response (abridged):

```json
{
  "requestId": "6f1c…",
  "exam": { "code": "JEE_MAIN", "name": "Joint Entrance Examination (Main)" },
  "academicYear": 2026,
  "measure": "rank",
  "rankUsed": 45821,
  "rankIsEstimated": false,
  "scoreUsed": null,
  "maxScoreUsed": null,
  "category": "OBC_NCL",
  "homeState": "UP",
  "counts": {
    "strong_historical_match": 4,
    "historical_match": 11,
    "borderline": 6,
    "outside_historical_range": 0
  },
  "matches": [
    {
      "collegeBranchId": 5821,
      "college": { "id": 74, "name": "…", "type": "NIT", "state": "Uttar Pradesh" },
      "branch": { "id": 1, "code": "CSE", "name": "Computer Science and Engineering" },
      "seatType": "OBC-NCL",
      "quota": "Home State",
      "genderPool": "Gender-Neutral",
      "grade": "historical_match",
      "gradeLabel": "Historical match",
      "score": 63.4,
      "weightedClosingRank": 46400,
      "bestClosingRank": 44000,
      "worstClosingRank": 51000,
      "rankMargin": 579,
      "scoreBand": null,
      "yearsAvailable": 4,
      "trend": "tightening",
      "cutoffHistory": [
        { "year": 2026, "opening": 39100, "closing": 44000, "round": 5 }
      ]
    }
  ],
  "disclaimer": "These results are based on published closing ranks…"
}
```

### Marks-based exams

BITS admits on a BITSAT score, so `/prediction` runs a second engine for it and
returns the same envelope with the other half filled in:

```json
{
  "measure": "score",
  "rankUsed": null,
  "scoreUsed": 300,
  "maxScoreUsed": 390,
  "matches": [
    {
      "grade": "borderline",
      "score": 40.63,
      "weightedClosingRank": null,
      "rankMargin": null,
      "scoreBand": {
        "weightedClosing": 312.9,
        "toughestClosing": 331,
        "easiestClosing": 304,
        "latestClosing": 308,
        "maxScore": 390,
        "margin": -12.9
      },
      "trend": "loosening",
      "cutoffHistory": [
        { "year": 2026, "opening": null, "closing": 308, "max": 390,
          "pct": 78.9744, "round": 1 }
      ]
    }
  ]
}
```

Every figure in `scoreBand` is out of the `maxScore` the candidate sent, so it
can be printed beside what they typed with no conversion. `cutoffHistory` keeps
each year's own `max`, which is not decoration: BITSAT was out of 450 through
2021 and 390 after, and a bare 306 next to a bare 226 reads as a collapse.

### Client contract

- `measure` decides which half of every match to read, and which way "better"
  points — a lower rank is better, a higher score is. Do not infer it from which
  fields happen to be non-null.
- `grade` is the value to branch on; `gradeLabel` is the string to show.
- `rankIsEstimated: true` means the rank came from a percentile conversion —
  show the estimate badge and `rankEstimateMethod`. It is never true on a score
  run.
- A score and a rank are never comparable. Two matches from different measures
  may sit side by side, but nothing may subtract, sort or rank them together.
- `disclaimer` is rendered below every result list. Do not drop it.
- There is no field that asserts admission, and none should be synthesised
  client-side.

## `POST /prediction/what-if`

Same body as `/prediction`, plus an optional `ranks` array (max 8) — or `scores`
for a marks-based exam. Omit it and the engine sweeps 0.6× to 1.6× of the real
rank, or 0.85× to 1.15× of the real score, clamped to the paper total. Returns
`baseline` plus one `scenarios[]` entry with grade counts and the top 10
matches; each entry carries `rank` or `score`, whichever applies, and null for
the other.

---

## Cut-off figures outside `/prediction`

`GET /colleges/{slug}`, `GET /colleges/compare` and `GET /shortlist` all report a
programme's most recent cut-off, and all three read `v_program_latest_cutoff`,
which spans both measures. Each row carries:

| Field | Meaning |
| ----- | ------- |
| `measure` | `rank` or `score`. Null when nothing is published for that programme. |
| `latest_closing` | The figure. A rank, or a score out of `latest_max_score`. |
| `latest_max_score` | The paper total. Null on a rank. |
| `latest_year` | Which year the figure is from. |

The compare table may hold both kinds in one row — BITS beside an IIT — and the
client shows them side by side without marking a winner, because a score of
308/390 and a rank of 67 are not on one scale.
