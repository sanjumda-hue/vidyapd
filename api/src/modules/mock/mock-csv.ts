import { BadRequestException } from '@nestjs/common';

import { KeyQuestion, QuestionKind } from './mock-scoring';

/**
 * Reading the two sheets a student uploads.
 *
 * Deliberately not TabularParser: that one requires an institute and a
 * programme column and exists to turn a counselling export into cutoffs.
 * These are two narrow files, and their failures need to be explained to a
 * student holding a spreadsheet rather than logged for an importer.
 *
 * Headers are matched loosely, because the same column comes back as
 * "Question No", "Q.No", "q_no" and "Question Number" depending on who made
 * the sheet.
 */

const COLUMNS: Record<string, string[]> = {
  questionNo: ['question no', 'question number', 'q no', 'qno', 'q', 'question', 'sl no', 'sno'],
  section: ['section', 'subject', 'part'],
  kind: ['type', 'question type', 'kind'],
  correctAnswer: ['correct answer', 'answer key', 'key', 'correct', 'answer'],
  givenAnswer: ['your answer', 'marked answer', 'response', 'given answer', 'answer', 'marked'],
  marksCorrect: ['marks', 'marks correct', 'positive marks', 'max marks'],
  marksWrong: ['negative marks', 'negative', 'penalty', 'marks wrong'],
};

const norm = (s: string) => s.toLowerCase().replace(/[^a-z0-9]+/g, ' ').trim();

/** Minimal RFC4180-ish split: quoted fields, doubled quotes, commas inside. */
function splitRow(line: string): string[] {
  const out: string[] = [];
  let cur = '';
  let quoted = false;
  for (let i = 0; i < line.length; i += 1) {
    const ch = line[i];
    if (quoted) {
      if (ch === '"') {
        if (line[i + 1] === '"') { cur += '"'; i += 1; } else quoted = false;
      } else cur += ch;
    } else if (ch === '"') quoted = true;
    else if (ch === ',') { out.push(cur); cur = ''; }
    else cur += ch;
  }
  out.push(cur);
  return out.map((c) => c.trim());
}

function parseGrid(csv: string): { headers: string[]; rows: string[][] } {
  const lines = csv
    .split(/\r?\n/)
    .filter((l) => l.trim() !== '' && !/^,*$/.test(l.trim()));
  if (lines.length < 2) {
    throw new BadRequestException('The file needs a header row and at least one question.');
  }
  return { headers: splitRow(lines[0]), rows: lines.slice(1).map(splitRow) };
}

function mapHeaders(headers: string[]): Record<string, number> {
  const map: Record<string, number> = {};
  for (const [field, names] of Object.entries(COLUMNS)) {
    const i = headers.findIndex((h) => names.includes(norm(h)));
    if (i !== -1) map[field] = i;
  }
  return map;
}

function readKind(raw: string | undefined): QuestionKind {
  const v = norm(raw ?? '');
  if (!v) return 'mcq_single';
  if (/numeric|integer|nat|numerical/.test(v)) return 'numerical';
  if (/multi|more than one|msq/.test(v)) return 'mcq_multi';
  return 'mcq_single';
}

function readNum(raw: string | undefined): number | null {
  if (raw === undefined || raw.trim() === '') return null;
  const n = Number.parseFloat(raw.replace(/[^0-9.\-]/g, ''));
  return Number.isFinite(n) ? n : null;
}

/** The answer key: one row per question, with the correct answer. */
export function parseAnswerKey(csv: string): KeyQuestion[] {
  const { headers, rows } = parseGrid(csv);
  const map = mapHeaders(headers);

  const missing = ['questionNo', 'correctAnswer'].filter((k) => !(k in map));
  if (missing.length) {
    throw new BadRequestException(
      `The answer key needs a question number and a correct answer column. ` +
        `Found: ${headers.join(' | ')}`,
    );
  }

  const out: KeyQuestion[] = [];
  const seen = new Set<number>();
  rows.forEach((r, i) => {
    const no = readNum(r[map.questionNo]);
    const answer = (r[map.correctAnswer] ?? '').trim();
    // A trailing blank line or a "Total" footer row, not a question.
    if (no === null || answer === '') return;
    if (!Number.isInteger(no) || no < 1) {
      throw new BadRequestException(`Row ${i + 2}: "${r[map.questionNo]}" is not a question number.`);
    }
    if (seen.has(no)) {
      // Silently keeping the last one would score a paper against a key the
      // student cannot see.
      throw new BadRequestException(`Question ${no} appears twice in the answer key.`);
    }
    seen.add(no);
    out.push({
      questionNo: no,
      section: map.section !== undefined ? (r[map.section] || null) : null,
      kind: readKind(map.kind !== undefined ? r[map.kind] : undefined),
      correctAnswer: answer,
      marksCorrect: map.marksCorrect !== undefined ? readNum(r[map.marksCorrect]) : null,
      marksWrong: map.marksWrong !== undefined ? readNum(r[map.marksWrong]) : null,
    });
  });

  if (out.length === 0) {
    throw new BadRequestException('No questions were found in the answer key.');
  }
  return out.sort((a, b) => a.questionNo - b.questionNo);
}

/**
 * The response sheet: question number and what the student marked.
 *
 * "Answer" is ambiguous -- it names the key column too -- so a sheet with only
 * that header is read as the student's response, which is what a response
 * sheet means.
 */
export function parseResponses(csv: string): Map<number, string | null> {
  const { headers, rows } = parseGrid(csv);
  const map = mapHeaders(headers);

  if (!('questionNo' in map)) {
    throw new BadRequestException(
      `The response sheet needs a question number column. Found: ${headers.join(' | ')}`,
    );
  }
  const answerAt = map.givenAnswer ?? map.correctAnswer;
  if (answerAt === undefined) {
    throw new BadRequestException(
      `The response sheet needs an answer column. Found: ${headers.join(' | ')}`,
    );
  }

  const out = new Map<number, string | null>();
  rows.forEach((r, i) => {
    const no = readNum(r[map.questionNo]);
    if (no === null) return;
    if (!Number.isInteger(no) || no < 1) {
      throw new BadRequestException(`Row ${i + 2}: "${r[map.questionNo]}" is not a question number.`);
    }
    if (out.has(no)) {
      throw new BadRequestException(`Question ${no} is answered twice in the response sheet.`);
    }
    const v = (r[answerAt] ?? '').trim();
    out.set(no, v === '' ? null : v);
  });

  if (out.size === 0) {
    throw new BadRequestException('No responses were found in the sheet.');
  }
  return out;
}
