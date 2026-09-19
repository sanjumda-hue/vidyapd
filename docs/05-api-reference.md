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
| done | `POST /prediction` | Rank or percentile → historical matches |
| done | `POST /prediction/what-if` | Same profile at several hypothetical ranks |
| done | `GET  /prediction/{requestId}` | Replay a stored prediction from its snapshot |
| done | `GET  /cutoffs/program/{id}` | Year-by-year opening/closing ranks |
| done | `GET  /cutoffs/program/{id}/trend` | Aggregated trend row for the chart |
| todo | `GET  /exams`, `/exams/{code}`, `/exams/{code}/schedule` | |
| todo | `GET  /calendar?from&to` | Month grid, backed by `v_exam_calendar` |
| todo | `GET  /colleges`, `/colleges/{slug}`, `/colleges/{slug}/branches` | |
| todo | `GET  /branches`, `/branches/{code}` | |
| todo | `POST /compare` | Side-by-side, backed by `v_program_summary` |
| todo | `GET/POST/DELETE /shortlist` | Requires auth |
| todo | `POST /auth/register`, `/auth/login` | |
| todo | `GET/PATCH /users/me`, `/users/me/scores` | |
| todo | `GET /notifications`, `PATCH /notifications/{id}/read` | |
| todo | `GET/POST /admin/imports`, `/admin/imports/{id}/approve` | Admin role |

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

Send `percentile` instead of `rank` for a percentile-based exam. Exactly one of
the two is required.

Response (abridged):

```json
{
  "requestId": "6f1c…",
  "exam": { "code": "JEE_MAIN", "name": "Joint Entrance Examination (Main)" },
  "academicYear": 2026,
  "rankUsed": 45821,
  "rankIsEstimated": false,
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

### Client contract

- `grade` is the value to branch on; `gradeLabel` is the string to show.
- `rankIsEstimated: true` means the rank came from a percentile conversion —
  show the estimate badge and `rankEstimateMethod`.
- `disclaimer` is rendered below every result list. Do not drop it.
- There is no field that asserts admission, and none should be synthesised
  client-side.

## `POST /prediction/what-if`

Same body as `/prediction`, plus an optional `ranks` array (max 8). Omit it and
the engine sweeps 0.6× to 1.6× of the real rank. Returns `baseline` plus one
`scenarios[]` entry per rank with grade counts and the top 10 matches.
