import type { Content, ContentStatus } from '../../domain/content';

export type CreateContentInput = {
  teacherId: string;
  classId: string;
  disciplineId: string;
  title: string;
  description?: string | null;
};

export type UpdateContentInput = Partial<{
  title: string;
  description: string | null;
}>;

export interface ContentRepository {
  create(input: CreateContentInput): Promise<Content>;
  update(id: string, teacherId: string, input: UpdateContentInput): Promise<Content>;
  findById(id: string, teacherId: string): Promise<Content | null>;
  listByClass(
    classId: string,
    teacherId: string,
    status?: ContentStatus,
    disciplineId?: string,
  ): Promise<Content[]>;
  setStatus(id: string, teacherId: string, status: ContentStatus, completedAt: Date | null): Promise<Content>;
}
