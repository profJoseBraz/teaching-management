export interface LessonContentRepository {
  exists(lessonId: string, contentId: string): Promise<boolean>;
  link(lessonId: string, contentId: string): Promise<void>;
  unlink(lessonId: string, contentId: string): Promise<void>;
}
