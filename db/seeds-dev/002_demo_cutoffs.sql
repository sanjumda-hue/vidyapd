-- DEVELOPMENT DATA ONLY -- these closing ranks are invented.
--
-- Generates 4 years x 6 branches x 6 colleges x every seat type/gender
-- combination for the AI and HS quotas. Ranks are derived from a per-college
-- base multiplied by a branch factor, with a small year-on-year drift, so the
-- trend view and the grading bands have realistic-looking spread to work with.

BEGIN;

INSERT INTO cutoff_data (
  academic_year, counselling_process_id, counselling_round_id, round_no, exam_id,
  college_branch_id, college_id, branch_id,
  seat_type_id, category_id, quota_id, gender_id,
  opening_rank, closing_rank, rank_basis, is_verified
)
SELECT
  cp.academic_year, cp.id, cr.id, cr.round_no, e.id,
  cb.id, cb.college_id, cb.branch_id,
  st.id, st.category_id, q.id, g.id,
  GREATEST(1, (closing * 0.82)::BIGINT),
  closing,
  'category_rank',
  false
FROM (
  SELECT
    cb.id                AS cb_id,
    cb.college_id,
    cb.branch_id,
    cp.id                AS cp_id,
    cp.academic_year,
    st.id                AS st_id,
    q.id                 AS q_id,
    g.id                 AS g_id,
    -- base rank by college tier x branch desirability x category relaxation
    -- x female-pool relaxation, drifting ~4% per year older.
    GREATEST(1, round(
        base.rank_base
      * br.factor
      * cat.relax
      * CASE WHEN g.code = 'FEMALE_ONLY' THEN 1.45 ELSE 1.0 END
      * CASE WHEN q.code = 'HS' THEN 1.30 ELSE 1.0 END
      * (1 + (2026 - cp.academic_year) * 0.04)
    ))::BIGINT AS closing
  FROM college_branches cb
  JOIN colleges col ON col.id = cb.college_id AND col.slug LIKE 'demo-%'
  JOIN branches b   ON b.id = cb.branch_id
  JOIN counselling_processes cp ON cp.code LIKE 'JOSAA_20%'
  JOIN seat_types st ON NOT st.is_pwd
  JOIN categories cat_t ON cat_t.id = st.category_id
  JOIN quotas q   ON q.code IN ('AI', 'HS')
  JOIN genders g  ON true
  JOIN (VALUES
    ('demo-iit-up',   1200), ('demo-nit-ka',  9000), ('demo-nit-up', 16000),
    ('demo-iiit-mh', 26000), ('demo-govt-dl', 34000), ('demo-priv-ka', 90000)
  ) AS base(slug, rank_base) ON base.slug = col.slug
  JOIN (VALUES
    ('CSE', 1.0), ('IT', 1.6), ('ECE', 2.3), ('EE', 3.1), ('ME', 4.2), ('CE', 5.6)
  ) AS br(code, factor) ON br.code = b.code
  JOIN (VALUES
    ('OPEN', 1.0), ('EWS', 1.35), ('OBC_NCL', 1.9), ('SC', 4.5), ('ST', 7.0)
  ) AS cat(code, relax) ON cat.code = cat_t.code
) AS gen
JOIN college_branches cb      ON cb.id = gen.cb_id
JOIN counselling_processes cp ON cp.id = gen.cp_id
JOIN counselling_rounds cr    ON cr.counselling_process_id = cp.id AND cr.round_no = 5
JOIN exams e                  ON e.code = 'JEE_MAIN'
JOIN seat_types st            ON st.id = gen.st_id
JOIN quotas q                 ON q.id = gen.q_id
JOIN genders g                ON g.id = gen.g_id
ON CONFLICT DO NOTHING;

COMMIT;
