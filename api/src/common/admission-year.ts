/**
 * The admission season a given moment belongs to.
 *
 * The counselling year rolls over mid-year: a search run in March 2026 is still
 * shopping against the 2025 season, because 2026's cut-offs do not exist yet.
 * June is the boundary.
 *
 * Shared because two services now depend on agreeing about it. The prediction
 * service uses it to pick which year to query; the reference service uses it to
 * decide whether a percentile can be converted for that year. If those two
 * disagreed by one, the form would offer an input the engine then refuses.
 */
export function currentAdmissionYear(now: Date = new Date()): number {
  return now.getMonth() >= 5 ? now.getFullYear() : now.getFullYear() - 1;
}
