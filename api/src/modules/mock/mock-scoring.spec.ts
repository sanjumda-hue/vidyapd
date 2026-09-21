import { isAnswerCorrect, scoreAttempt, KeyQuestion, ScoringScheme } from './mock-scoring';

/**
 * Scoring is the number a student takes away from this feature, so the rules
 * that decide it are pinned individually. The marking schemes below are the
 * published ones for each exam, which is the whole reason scoring is
 * exam-wise: COMEDK has no negative marking at all, and applying JEE Main's
 * to it would invent a penalty.
 */
const JEE_MAIN: ScoringScheme = {
  marksCorrect: 4, marksWrong: 1, marksSkipped: 0, numericTolerance: 0,
};
const BITSAT: ScoringScheme = {
  marksCorrect: 3, marksWrong: 1, marksSkipped: 0, numericTolerance: 0,
};
const COMEDK: ScoringScheme = {
  marksCorrect: 1, marksWrong: 0, marksSkipped: 0, numericTolerance: 0,
};

const mcq = (n: number, ans: string, section = 'Physics'): KeyQuestion => ({
  questionNo: n, kind: 'mcq_single', correctAnswer: ans, section,
});

describe('answer matching', () => {
  it('ignores case and punctuation on options', () => {
    expect(isAnswerCorrect('mcq_single', 'a', 'A', 0)).toBe(true);
    expect(isAnswerCorrect('mcq_single', ' B ', 'B', 0)).toBe(true);
  });

  it('accepts a multi-answer typed in any order', () => {
    // "CA" and "A,C" are the same answer; only a string comparison disagrees.
    expect(isAnswerCorrect('mcq_multi', 'CA', 'A,C', 0)).toBe(true);
    expect(isAnswerCorrect('mcq_multi', 'a c', 'AC', 0)).toBe(true);
  });

  it('does not treat a partial multi-answer as correct', () => {
    expect(isAnswerCorrect('mcq_multi', 'A', 'AC', 0)).toBe(false);
  });

  it('matches numerical answers that are the same number written differently', () => {
    expect(isAnswerCorrect('numerical', '9.80', '9.8', 0)).toBe(true);
    expect(isAnswerCorrect('numerical', '.5', '0.5', 0)).toBe(true);
    expect(isAnswerCorrect('numerical', '-3', '-3.0', 0)).toBe(true);
  });

  it('honours the numerical tolerance, and its edge', () => {
    expect(isAnswerCorrect('numerical', '9.79', '9.8', 0.01)).toBe(true);
    expect(isAnswerCorrect('numerical', '9.7', '9.8', 0.01)).toBe(false);
  });

  it('is not fooled by an unparseable numerical answer', () => {
    expect(isAnswerCorrect('numerical', 'abc', '9.8', 0.5)).toBe(false);
  });
});

describe('scoring, exam by exam', () => {
  const key = [mcq(1, 'A'), mcq(2, 'B'), mcq(3, 'C'), mcq(4, 'D')];

  it('JEE Main: +4 correct, -1 wrong, 0 for a blank', () => {
    const r = scoreAttempt(
      key,
      new Map([[1, 'A'], [2, 'X'], [3, null], [4, 'D']]),
      JEE_MAIN,
    );
    expect(r.correct).toBe(2);
    expect(r.wrong).toBe(1);
    expect(r.skipped).toBe(1);
    expect(r.score).toBe(7); // 4 + 4 - 1 + 0
    expect(r.maxMarks).toBe(16);
  });

  it('BITSAT: +3 correct, -1 wrong', () => {
    const r = scoreAttempt(key, new Map([[1, 'A'], [2, 'X']]), BITSAT);
    expect(r.score).toBe(2); // 3 - 1, two left blank
    expect(r.skipped).toBe(2);
  });

  it('COMEDK: a wrong answer costs nothing', () => {
    // The reason the scheme lives on the paper. Scoring this with JEE Main's
    // rules would take a mark the exam never takes.
    const r = scoreAttempt(key, new Map([[1, 'A'], [2, 'X'], [3, 'Y'], [4, 'Z']]), COMEDK);
    expect(r.score).toBe(1);
    expect(r.wrong).toBe(3);
  });

  it('never rewards a wrong answer even if a scheme carries a negative', () => {
    const r = scoreAttempt(
      [mcq(1, 'A')],
      new Map([[1, 'B']]),
      { ...JEE_MAIN, marksWrong: -1 },
    );
    expect(r.score).toBe(-1);
  });
});

describe('blanks', () => {
  it('treats the ways a sheet says "not attempted" the same', () => {
    const key = [mcq(1, 'A'), mcq(2, 'A'), mcq(3, 'A'), mcq(4, 'A'), mcq(5, 'A')];
    const r = scoreAttempt(
      key,
      new Map<number, string | null>([[1, ''], [2, '-'], [3, 'NA'], [4, 'not attempted'], [5, '  ']]),
      JEE_MAIN,
    );
    expect(r.skipped).toBe(5);
    expect(r.wrong).toBe(0);
    expect(r.score).toBe(0);
  });

  it('counts a question missing from the response sheet as skipped', () => {
    // A sheet that stops at question 2 has not got question 3 wrong.
    const r = scoreAttempt([mcq(1, 'A'), mcq(2, 'B'), mcq(3, 'C')], new Map([[1, 'A']]), JEE_MAIN);
    expect(r.correct).toBe(1);
    expect(r.skipped).toBe(2);
    expect(r.wrong).toBe(0);
    expect(r.score).toBe(4);
  });
});

describe('per-question overrides and sections', () => {
  it('lets a question carry its own marks', () => {
    // JEE Advanced varies marks by section inside one paper.
    const r = scoreAttempt(
      [
        { questionNo: 1, kind: 'mcq_single', correctAnswer: 'A', section: 'P', marksCorrect: 4, marksWrong: 2 },
        { questionNo: 2, kind: 'mcq_single', correctAnswer: 'B', section: 'P', marksCorrect: 3, marksWrong: 0 },
      ],
      new Map([[1, 'X'], [2, 'B']]),
      JEE_MAIN,
    );
    expect(r.score).toBe(1); // -2 then +3
    expect(r.maxMarks).toBe(7);
  });

  it('breaks the score down by section', () => {
    const r = scoreAttempt(
      [mcq(1, 'A', 'Physics'), mcq(2, 'B', 'Chemistry'), mcq(3, 'C', 'Chemistry')],
      new Map([[1, 'A'], [2, 'B'], [3, 'X']]),
      JEE_MAIN,
    );
    const byName = Object.fromEntries(r.sections.map((s) => [s.section, s]));
    expect(byName['Physics'].score).toBe(4);
    expect(byName['Chemistry'].score).toBe(3); // 4 - 1
  });

  it('rounds away floating point noise from quarter-mark schemes', () => {
    const r = scoreAttempt(
      [mcq(1, 'A'), mcq(2, 'A'), mcq(3, 'A')],
      new Map([[1, 'X'], [2, 'X'], [3, 'X']]),
      { marksCorrect: 1, marksWrong: 0.25, marksSkipped: 0, numericTolerance: 0 },
    );
    expect(r.score).toBe(-0.75);
  });
});

describe('answer status', () => {
  it('tells a skipped question apart from a wrong one', () => {
    // isCorrect is false for both, so anything rendering from it alone marks a
    // blank red and tells the student they got wrong what they never answered.
    const r = scoreAttempt(
      [mcq(1, 'A'), mcq(2, 'A'), mcq(3, 'A')],
      new Map<number, string | null>([[1, 'A'], [2, 'B'], [3, null]]),
      JEE_MAIN,
    );
    expect(r.answers.map((a) => a.status)).toEqual(['correct', 'wrong', 'skipped']);
  });
});
