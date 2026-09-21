-- =============================================================================
-- 028_exam_attribution_by_college_type.sql
-- Re-file the cutoffs that were attributed to the wrong exam.
--
-- counselling_exams.applies_to_college_types has said since 004 that JoSAA
-- allots IIT seats on JEE Advanced and everything else on JEE Main. The
-- publisher never read it: it took the process's is_primary exam and stamped
-- it on every row, so 68,863 IIT cutoffs were filed under JEE Main.
--
-- That is not a labelling nicety. An IIT closing rank is a JEE Advanced rank,
-- drawn from a different exam and a different candidate pool, so:
--
--   a JEE Main rank of 500 was compared against IIT Delhi EE closing at 610
--   and reported as a "strong historical match"
--
--   a real JEE Advanced rank returned nothing at all, because no row in the
--   database carried that exam_id
--
-- One of those is false encouragement and the other is a dead feature. The
-- publisher now resolves the exam per row from the college's type; this moves
-- what is already stored.
--
-- Driven by applies_to_college_types rather than naming IITs, so it repairs
-- any authority that splits its intake across exams. Today that is JoSAA
-- alone: CSAB fills NIT+ vacancies from the JEE Main list and links no second
-- exam, so none of its rows move.
--
-- exam_id is part of uq_cutoff_natural but not of the partition key, so this
-- is an in-place update with no row movement. Checked before writing: zero of
-- these rows collide with an existing row at the destination exam_id.
-- =============================================================================

BEGIN;

UPDATE cutoff_data cd
SET exam_id = ce.exam_id
FROM counselling_exams ce, colleges co
WHERE ce.counselling_process_id = cd.counselling_process_id
  AND co.id = cd.college_id
  AND co.college_type = ANY (ce.applies_to_college_types)
  AND cd.exam_id <> ce.exam_id;

COMMIT;

-- Both trend views key on exam_id, so they describe the old attribution until
-- they are rebuilt.
SELECT fn_refresh_cutoff_trend(false);
