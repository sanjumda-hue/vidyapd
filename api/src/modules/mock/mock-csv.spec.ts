import { parseAnswerKey, parseResponses } from './mock-csv';

/**
 * These two files arrive from students, not from an importer, so every failure
 * here has to come back as something a person holding a spreadsheet can act
 * on. The cases below are the ways a real sheet differs from a tidy one.
 */
describe('parseAnswerKey', () => {
  it('reads a plain key', () => {
    const k = parseAnswerKey(
      'Question No,Section,Type,Correct Answer\n1,Physics,MCQ,A\n2,Physics,Numerical,9.8',
    );
    expect(k).toHaveLength(2);
    expect(k[0]).toMatchObject({ questionNo: 1, section: 'Physics', kind: 'mcq_single', correctAnswer: 'A' });
    expect(k[1]).toMatchObject({ questionNo: 2, kind: 'numerical', correctAnswer: '9.8' });
  });

  it('accepts the header spellings sheets actually use', () => {
    const k = parseAnswerKey('Q.No,Subject,Key\n1,Chemistry,B');
    expect(k[0]).toMatchObject({ questionNo: 1, section: 'Chemistry', correctAnswer: 'B' });
  });

  it('carries per-question marks when the sheet gives them', () => {
    const k = parseAnswerKey('Q No,Answer,Marks,Negative Marks\n1,A,4,2');
    expect(k[0].marksCorrect).toBe(4);
    expect(k[0].marksWrong).toBe(2);
  });

  it('sorts by question number, however the file was ordered', () => {
    const k = parseAnswerKey('Q No,Answer\n3,C\n1,A\n2,B');
    expect(k.map((q) => q.questionNo)).toEqual([1, 2, 3]);
  });

  it('handles quoted fields with commas', () => {
    const k = parseAnswerKey('Q No,Section,Answer\n1,"Physics, Part A",A');
    expect(k[0].section).toBe('Physics, Part A');
  });

  it('skips a trailing total row rather than reading it as a question', () => {
    const k = parseAnswerKey('Q No,Answer\n1,A\n2,B\nTotal,\n');
    expect(k).toHaveLength(2);
  });

  it('refuses a duplicated question instead of quietly keeping one', () => {
    // Scoring against a key the student cannot see is worse than not scoring.
    expect(() => parseAnswerKey('Q No,Answer\n1,A\n1,B')).toThrow(/appears twice/i);
  });

  it('names the columns it found when a required one is missing', () => {
    expect(() => parseAnswerKey('Serial,Marks\n1,4')).toThrow(/Serial \| Marks/);
  });

  it('refuses a file with no questions in it', () => {
    expect(() => parseAnswerKey('Q No,Answer\n')).toThrow(/header row and at least one question/i);
  });
});

describe('parseResponses', () => {
  it('reads a response sheet', () => {
    const r = parseResponses('Question No,Your Answer\n1,A\n2,C');
    expect(r.get(1)).toBe('A');
    expect(r.get(2)).toBe('C');
  });

  it('reads a sheet whose only answer column is called "Answer"', () => {
    // Ambiguous with the key's column; on a response sheet it is the response.
    const r = parseResponses('Q No,Answer\n1,B');
    expect(r.get(1)).toBe('B');
  });

  it('keeps a blank as not-attempted rather than dropping the row', () => {
    const r = parseResponses('Q No,Response\n1,A\n2,\n3,D');
    expect(r.has(2)).toBe(true);
    expect(r.get(2)).toBeNull();
    expect(r.size).toBe(3);
  });

  it('refuses a question answered twice', () => {
    expect(() => parseResponses('Q No,Response\n1,A\n1,B')).toThrow(/answered twice/i);
  });

  it('refuses a sheet with no question number column', () => {
    expect(() => parseResponses('Name,Answer\nAnil,A')).toThrow(/question number column/i);
  });
});
