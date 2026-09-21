import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';

import { PrismaService } from '../../database/prisma.service';
import { parseAnswerKey, parseResponses } from './mock-csv';
import { KeyQuestion, ScoringScheme, scoreAttempt } from './mock-scoring';

export interface CreatePaperInput {
  examCode: string;
  title: string;
  code?: string;
  academicYear?: number;
  marksCorrect?: number;
  marksWrong?: number;
  marksSkipped?: number;
  numericTolerance?: number;
  sourceNote?: string;
  /** The answer key, as the uploaded file's text. */
  answerKeyCsv: string;
}

/**
 * The marking scheme to fall back on when an upload does not state one.
 *
 * Only the exams whose scheme is fixed and unambiguous. JEE Advanced changes
 * its marking every year and varies it by section within a paper, and the
 * state CETs differ on negative marking, so those have no default here: the
 * upload has to say, and the paper records what it was told. Guessing a
 * penalty an exam does not have is the one mistake this feature must not make.
 */
const DEFAULT_SCHEMES: Record<string, { correct: number; wrong: number }> = {
  JEE_MAIN: { correct: 4, wrong: 1 },
  BITSAT: { correct: 3, wrong: 1 },
  COMEDK_UGET: { correct: 1, wrong: 0 },
};

@Injectable()
export class MockService {
  constructor(private readonly prisma: PrismaService) {}

  /**
   * The papers this student can pick from: their own, plus any with no
   * uploader, which is how the seeded and shared ones are stored.
   *
   * Not every paper on the instance. A paper's title is the student's own
   * words ("JEE Main 2025, third attempt"), and there is no reason for it to
   * show up in somebody else's list.
   */
  async listPapers(userId: bigint, examCode?: string) {
    const rows = await this.prisma.$queryRaw<
      Array<{
        id: number; code: string; title: string; exam_code: string; exam_name: string;
        academic_year: number | null; total_questions: number; max_marks: string;
        marks_correct: string; marks_wrong: string; attempts: number;
      }>
    >`
      SELECT p.id, p.code, p.title, e.code AS exam_code, e.name AS exam_name,
             p.academic_year, p.total_questions, p.max_marks::TEXT,
             p.marks_correct::TEXT, p.marks_wrong::TEXT,
             (SELECT count(*)::int FROM mock_attempts a WHERE a.mock_paper_id = p.id) AS attempts
      FROM mock_papers p
      JOIN exams e ON e.id = p.exam_id
      WHERE (p.uploaded_by = ${userId} OR p.uploaded_by IS NULL)
        AND (${examCode ?? null}::TEXT IS NULL OR e.code = ${examCode ?? null}::TEXT)
      ORDER BY p.created_at DESC
    `;
    return rows.map((r) => ({
      id: r.id,
      code: r.code,
      title: r.title,
      exam: { code: r.exam_code, name: r.exam_name },
      academicYear: r.academic_year,
      totalQuestions: r.total_questions,
      maxMarks: Number(r.max_marks),
      marksCorrect: Number(r.marks_correct),
      marksWrong: Number(r.marks_wrong),
      attempts: r.attempts,
    }));
  }

  async createPaper(input: CreatePaperInput, userId?: bigint) {
    const exam = await this.prisma.exams.findUnique({
      where: { code: input.examCode },
      select: { id: true, code: true },
    });
    if (!exam) throw new NotFoundException(`Unknown exam code: ${input.examCode}`);

    const key = parseAnswerKey(input.answerKeyCsv);

    // Explicit scheme, else the exam's published one, else refuse. Inventing a
    // penalty is worse than asking for it.
    const fallback = DEFAULT_SCHEMES[exam.code];
    const marksCorrect = input.marksCorrect ?? fallback?.correct;
    const marksWrong = input.marksWrong ?? fallback?.wrong;
    if (marksCorrect === undefined || marksWrong === undefined) {
      throw new BadRequestException(
        `No marking scheme on record for ${exam.code}. Send marksCorrect and marksWrong, ` +
          `or put Marks and Negative Marks columns in the answer key.`,
      );
    }
    if (marksCorrect <= 0) {
      throw new BadRequestException('marksCorrect must be greater than zero.');
    }
    if (marksWrong < 0) {
      throw new BadRequestException('marksWrong is the amount deducted, so it cannot be negative.');
    }

    const maxMarks = key.reduce((sum, q) => sum + (q.marksCorrect ?? marksCorrect), 0);
    const code =
      input.code?.trim() ||
      `${exam.code}_${input.academicYear ?? new Date().getFullYear()}_${Date.now()}`;

    return this.prisma.$transaction(async (tx) => {
      const paper = await tx.mock_papers.create({
        data: {
          exam_id: exam.id,
          code,
          title: input.title.trim(),
          academic_year: input.academicYear ?? null,
          marks_correct: marksCorrect,
          marks_wrong: marksWrong,
          marks_skipped: input.marksSkipped ?? 0,
          numeric_tolerance: input.numericTolerance ?? 0,
          total_questions: key.length,
          max_marks: maxMarks,
          source_note: input.sourceNote ?? null,
          uploaded_by: userId ?? null,
        },
        select: { id: true, code: true },
      });

      await tx.mock_paper_questions.createMany({
        data: key.map((q) => ({
          mock_paper_id: paper.id,
          question_no: q.questionNo,
          section: q.section ?? null,
          kind: q.kind,
          correct_answer: q.correctAnswer,
          marks_correct: q.marksCorrect ?? null,
          marks_wrong: q.marksWrong ?? null,
        })),
      });

      return {
        id: paper.id,
        code: paper.code,
        totalQuestions: key.length,
        maxMarks,
        marksCorrect,
        marksWrong,
        sections: [...new Set(key.map((q) => q.section).filter(Boolean))],
      };
    });
  }

  /** Score a response sheet against a paper's key and keep the result. */
  async submitAttempt(paperId: number, responsesCsv: string, userId?: bigint) {
    const paper = await this.prisma.mock_papers.findUnique({
      where: { id: paperId },
      select: {
        id: true, title: true, marks_correct: true, marks_wrong: true,
        marks_skipped: true, numeric_tolerance: true,
        exams: { select: { code: true, name: true } },
      },
    });
    if (!paper) throw new NotFoundException(`No mock paper with id ${paperId}`);

    const questions = await this.prisma.mock_paper_questions.findMany({
      where: { mock_paper_id: paperId },
      orderBy: { question_no: 'asc' },
    });

    const key: KeyQuestion[] = questions.map((q) => ({
      questionNo: q.question_no,
      kind: q.kind as KeyQuestion['kind'],
      correctAnswer: q.correct_answer,
      section: q.section,
      marksCorrect: q.marks_correct === null ? null : Number(q.marks_correct),
      marksWrong: q.marks_wrong === null ? null : Number(q.marks_wrong),
    }));

    const responses = parseResponses(responsesCsv);

    // A sheet numbered beyond the paper is the wrong sheet, not a zero.
    const extra = [...responses.keys()].filter((n) => !key.some((q) => q.questionNo === n));
    if (extra.length > 0) {
      throw new BadRequestException(
        `The response sheet answers question${extra.length > 1 ? 's' : ''} ` +
          `${extra.slice(0, 5).join(', ')}${extra.length > 5 ? '…' : ''}, which this paper does not have. ` +
          `Is it the sheet for "${paper.title}"?`,
      );
    }

    const scheme: ScoringScheme = {
      marksCorrect: Number(paper.marks_correct),
      marksWrong: Number(paper.marks_wrong),
      marksSkipped: Number(paper.marks_skipped),
      numericTolerance: Number(paper.numeric_tolerance),
    };
    const result = scoreAttempt(key, responses, scheme);

    const attempt = await this.prisma.$transaction(async (tx) => {
      const a = await tx.mock_attempts.create({
        data: {
          mock_paper_id: paperId,
          user_id: userId ?? null,
          score: result.score,
          max_marks: result.maxMarks,
          correct: result.correct,
          wrong: result.wrong,
          skipped: result.skipped,
        },
        select: { id: true, uuid: true, attempted_at: true },
      });
      await tx.mock_attempt_answers.createMany({
        data: result.answers.map((r) => ({
          mock_attempt_id: a.id,
          question_no: r.questionNo,
          given_answer: r.givenAnswer,
          // Copied, so correcting the key later cannot rewrite this result.
          correct_answer: r.correctAnswer,
          is_correct: r.isCorrect,
          awarded: r.awarded,
        })),
      });
      return a;
    });

    return {
      attemptId: attempt.uuid,
      attemptedAt: attempt.attempted_at,
      paper: { id: paper.id, title: paper.title, exam: paper.exams },
      score: result.score,
      maxMarks: result.maxMarks,
      percentage: result.maxMarks > 0
        ? Math.round((result.score / result.maxMarks) * 1000) / 10
        : 0,
      correct: result.correct,
      wrong: result.wrong,
      skipped: result.skipped,
      scheme: { marksCorrect: scheme.marksCorrect, marksWrong: scheme.marksWrong },
      sections: result.sections,
      answers: result.answers,
    };
  }

  async listAttempts(userId: bigint) {
    const rows = await this.prisma.$queryRaw<
      Array<{
        uuid: string; title: string; exam_code: string; score: string; max_marks: string;
        correct: number; wrong: number; skipped: number; attempted_at: Date;
      }>
    >`
      SELECT a.uuid, p.title, e.code AS exam_code, a.score::TEXT, a.max_marks::TEXT,
             a.correct, a.wrong, a.skipped, a.attempted_at
      FROM mock_attempts a
      JOIN mock_papers p ON p.id = a.mock_paper_id
      JOIN exams e ON e.id = p.exam_id
      WHERE a.user_id = ${userId}
      ORDER BY a.attempted_at DESC
      LIMIT 50
    `;
    return rows.map((r) => ({
      attemptId: r.uuid,
      title: r.title,
      examCode: r.exam_code,
      score: Number(r.score),
      maxMarks: Number(r.max_marks),
      correct: r.correct,
      wrong: r.wrong,
      skipped: r.skipped,
      attemptedAt: r.attempted_at,
    }));
  }
}
