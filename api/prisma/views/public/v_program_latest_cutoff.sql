SELECT
  t.counselling_authority_id,
  t.exam_id,
  t.college_branch_id,
  t.college_id,
  t.branch_id,
  t.seat_type_id,
  t.category_id,
  t.quota_id,
  t.gender_id,
  'rank' :: text AS measure,
  (t.latest_closing_rank) :: numeric AS latest_closing,
  NULL :: numeric AS latest_max_score,
  t.latest_year,
  t.years_available,
  t.trend_slope
FROM
  mv_program_cutoff_trend t
UNION
ALL
SELECT
  s.counselling_authority_id,
  s.exam_id,
  s.college_branch_id,
  s.college_id,
  s.branch_id,
  s.seat_type_id,
  s.category_id,
  s.quota_id,
  s.gender_id,
  'score' :: text AS measure,
  s.latest_closing_score AS latest_closing,
  s.latest_max_score,
  s.latest_year,
  s.years_available,
  s.trend_slope
FROM
  mv_program_score_trend s;