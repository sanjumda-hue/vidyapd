/**
 * Scoring a mock attempt against an answer key.
 *
 * Pure, and kept out of the service on purpose: this is where a paper turns
 * into a number the student believes, and the awkward parts -- a multi-answer
 * question typed in a different order, a numerical answer a hair off, a blank
 * that must not be penalised -- are all decided here where they can be tested
 * without a database.
 */

export interface ScoringScheme {
  /** Awarded for a correct answer. */
  marksCorrect: number;
  /** Subtracted for a wrong one. Held positive; never added. */
  marksWrong: number;
  /** Usually 0. A few papers pay nothing and penalise nothing for a blank. */
  marksSkipped: number;
  /** How far a numerical answer may be off and still count. */
  numericTolerance: number;
}

export type QuestionKind = 'mcq_single' | 'mcq_multi' | 'numerical';

export interface KeyQuestion {
  questionNo: number;
  kind: QuestionKind;
  correctAnswer: string;
  section?: string | null;
  /** Per-question overrides; JEE Advanced varies marks by section. */
  marksCorrect?: number | null;
  marksWrong?: number | null;
}

export type AnswerStatus = 'correct' | 'wrong' | 'skipped';

export interface ScoredAnswer {
  questionNo: number;
  section: string | null;
  givenAnswer: string | null;
  correctAnswer: string;
  /**
   * Three states, not two.
   *
   * isCorrect alone is false for a skipped question as well as a wrong one,
   * and anything rendering from it marks blanks red -- which tells a student
   * they got wrong an answer they never gave. Kept alongside isCorrect so the
   * simple check still reads naturally.
   */
  status: AnswerStatus;
  isCorrect: boolean;
  awarded: number;
}

export interface ScoredAttempt {
  score: number;
  maxMarks: number;
  correct: number;
  wrong: number;
  skipped: number;
  answers: ScoredAnswer[];
  /** Per-section totals, for the breakdown the result screen shows. */
  sections: Array<{ section: string; score: number; correct: number; wrong: number; skipped: number }>;
}

/** Blank, a dash, or "not attempted" all mean the same thing on a real sheet. */
function isBlank(v: string | null | undefined): boolean {
  if (v === null || v === undefined) return true;
  const s = v.trim();
  return s === '' || s === '-' || s === '--' || /^(na|n\/a|none|skip|skipped|not attempted)$/i.test(s);
}

/**
 * Normalise an option answer.
 *
 * Papers and students disagree about case, separators and order: "A,C", "ac"
 * and "C A" are the same answer to a multi-correct question. Sorting the
 * letters makes them compare equal. Numbered options (1/2/3/4) are left as
 * digits and matched as written.
 */
function normaliseOptions(v: string): string {
  return v
    .toUpperCase()
    .replace(/[^A-Z0-9]/g, '')
    .split('')
    .sort()
    .join('');
}

/**
 * A numerical answer is correct within a tolerance.
 *
 * Exact string comparison fails on things that are the same number: "9.8" and
 * "9.80", "0.5" and ".5". Parsing and comparing with a tolerance is what the
 * real answer keys mean.
 */
function numericMatches(given: string, correct: string, tolerance: number): boolean {
  const g = Number.parseFloat(given.replace(/[^0-9eE+\-.]/g, ''));
  const c = Number.parseFloat(correct.replace(/[^0-9eE+\-.]/g, ''));
  if (!Number.isFinite(g) || !Number.isFinite(c)) return false;

  // Not a bare <= tolerance. 9.79 against 9.8 differs by
  // 0.010000000000000675 in binary floating point, so an answer sitting
  // exactly on a 0.01 tolerance was being marked wrong -- the one case where
  // a student is certain the machine is at fault, and right. The slack is
  // scaled by magnitude so it stays meaningless next to the numbers involved.
  const slack = 1e-9 * Math.max(1, Math.abs(g), Math.abs(c));
  return Math.abs(g - c) <= tolerance + slack;
}

export function isAnswerCorrect(
  kind: QuestionKind,
  given: string,
  correct: string,
  tolerance: number,
): boolean {
  if (kind === 'numerical') return numericMatches(given, correct, tolerance);
  return normaliseOptions(given) === normaliseOptions(correct) && normaliseOptions(given) !== '';
}

export function scoreAttempt(
  key: KeyQuestion[],
  responses: Map<number, string | null>,
  scheme: ScoringScheme,
): ScoredAttempt {
  const answers: ScoredAnswer[] = [];
  let score = 0;
  let correct = 0;
  let wrong = 0;
  let skipped = 0;
  let maxMarks = 0;

  const bySection = new Map<
    string,
    { section: string; score: number; correct: number; wrong: number; skipped: number }
  >();

  for (const q of key) {
    const plus = q.marksCorrect ?? scheme.marksCorrect;
    const minus = q.marksWrong ?? scheme.marksWrong;
    maxMarks += plus;

    const raw = responses.get(q.questionNo) ?? null;
    const blank = isBlank(raw);
    const given = blank ? null : (raw as string).trim();

    let awarded: number;
    let ok = false;
    if (blank) {
      awarded = scheme.marksSkipped;
      skipped += 1;
    } else if (isAnswerCorrect(q.kind, given as string, q.correctAnswer, scheme.numericTolerance)) {
      awarded = plus;
      ok = true;
      correct += 1;
    } else {
      // Held positive in the scheme and subtracted here, so a scheme can never
      // accidentally reward a wrong answer by carrying the wrong sign.
      awarded = -Math.abs(minus);
      wrong += 1;
    }

    score += awarded;
    answers.push({
      questionNo: q.questionNo,
      section: q.section ?? null,
      givenAnswer: given,
      correctAnswer: q.correctAnswer,
      status: blank ? 'skipped' : ok ? 'correct' : 'wrong',
      isCorrect: ok,
      awarded,
    });

    const name = q.section?.trim() || 'Overall';
    const sec = bySection.get(name) ?? { section: name, score: 0, correct: 0, wrong: 0, skipped: 0 };
    sec.score += awarded;
    if (blank) sec.skipped += 1;
    else if (ok) sec.correct += 1;
    else sec.wrong += 1;
    bySection.set(name, sec);
  }

  // Two decimals: schemes use quarter marks and floating point would otherwise
  // report 47.99999999999999.
  const round = (n: number) => Math.round(n * 100) / 100;

  return {
    score: round(score),
    maxMarks: round(maxMarks),
    correct,
    wrong,
    skipped,
    answers: answers.map((a) => ({ ...a, awarded: round(a.awarded) })),
    sections: [...bySection.values()].map((s) => ({ ...s, score: round(s.score) })),
  };
}
