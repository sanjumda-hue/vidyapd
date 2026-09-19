SELECT
  s.id AS schedule_id,
  s.academic_year,
  e.id AS exam_id,
  e.code AS exam_code,
  e.name AS exam_name,
  e.short_name AS exam_short_name,
  e.level AS exam_level,
  e.logo_url,
  st.code AS home_state_code,
  ses.session_no,
  ses.name AS session_name,
  s.event_type,
  s.event_name,
  s.start_date,
  s.end_date,
  s.start_at,
  s.end_at,
  s.is_tentative,
  COALESCE(s.detail_url, e.official_website) AS detail_url,
  s.notes
FROM
  (
    (
      (
        exam_schedules s
        JOIN exams e ON (
          (
            (e.id = s.exam_id)
            AND e.is_active
          )
        )
      )
      LEFT JOIN exam_sessions ses ON ((ses.id = s.exam_session_id))
    )
    LEFT JOIN states st ON ((st.id = e.home_state_id))
  );