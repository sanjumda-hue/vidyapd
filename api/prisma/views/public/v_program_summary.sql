SELECT
  cb.id AS college_branch_id,
  cb.program_name,
  cb.degree,
  cb.duration_years,
  cb.total_intake,
  c.id AS college_id,
  c.name AS college_name,
  c.short_name AS college_short_name,
  c.slug AS college_slug,
  c.college_type,
  c.ownership,
  c.nirf_rank_latest,
  c.has_hostel,
  st.id AS state_id,
  st.name AS state_name,
  ct.name AS city_name,
  b.id AS branch_id,
  b.code AS branch_code,
  b.name AS branch_name,
  sp.id AS specialization_id,
  sp.name AS specialization_name,
  f.tuition_fee_annual,
  f.academic_year AS fee_year,
  p.average_package,
  p.highest_package,
  p.placement_percentage,
  p.academic_year AS placement_year
FROM
  (
    (
      (
        (
          (
            (
              (
                college_branches cb
                JOIN colleges c ON ((c.id = cb.college_id))
              )
              JOIN states st ON ((st.id = c.state_id))
            )
            LEFT JOIN cities ct ON ((ct.id = c.city_id))
          )
          JOIN branches b ON ((b.id = cb.branch_id))
        )
        LEFT JOIN specializations sp ON ((sp.id = cb.specialization_id))
      )
      LEFT JOIN LATERAL (
        SELECT
          cf.tuition_fee_annual,
          cf.academic_year
        FROM
          college_fees cf
        WHERE
          (
            (cf.college_id = c.id)
            AND (
              (cf.college_branch_id = cb.id)
              OR (cf.college_branch_id IS NULL)
            )
          )
        ORDER BY
          cf.academic_year DESC,
          cf.college_branch_id
        LIMIT
          1
      ) f ON (TRUE)
    )
    LEFT JOIN LATERAL (
      SELECT
        pd.average_package,
        pd.highest_package,
        pd.placement_percentage,
        pd.academic_year
      FROM
        placement_data pd
      WHERE
        (
          (pd.college_id = c.id)
          AND (
            (pd.college_branch_id = cb.id)
            OR (pd.college_branch_id IS NULL)
          )
        )
      ORDER BY
        pd.academic_year DESC,
        pd.college_branch_id
      LIMIT
        1
    ) p ON (TRUE)
  )
WHERE
  (
    cb.is_active
    AND c.is_active
  );