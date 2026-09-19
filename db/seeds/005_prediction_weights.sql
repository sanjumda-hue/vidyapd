-- Seed: default prediction weighting (design doc section 13).
--
-- 40 / 30 / 20 / 10 across the four most recent years. Offset 4 is seeded at 0
-- so a fifth year of history is stored but ignored until someone deliberately
-- gives it weight.
BEGIN;

INSERT INTO prediction_weight_profiles
  (code, name, description, counselling_authority_id, is_active,
   strong_match_factor, borderline_factor, min_years_for_strong)
VALUES
  ('default', 'Default recency weighting',
   'Recency-weighted closing rank over the last four years, per design doc section 13.',
   NULL, true, 0.900, 1.100, 2)
ON CONFLICT (code) DO NOTHING;

INSERT INTO prediction_year_weights (profile_id, year_offset, weight)
SELECT p.id, v.year_offset, v.weight
FROM prediction_weight_profiles p
CROSS JOIN (VALUES
  (0::SMALLINT, 0.4000::NUMERIC),
  (1::SMALLINT, 0.3000::NUMERIC),
  (2::SMALLINT, 0.2000::NUMERIC),
  (3::SMALLINT, 0.1000::NUMERIC),
  (4::SMALLINT, 0.0000::NUMERIC)
) AS v(year_offset, weight)
WHERE p.code = 'default'
ON CONFLICT (profile_id, year_offset) DO NOTHING;

COMMIT;
