import type { Request, Response } from 'express';
import type { ParamsDictionary } from 'express-serve-static-core';
import type { CreateAcademicYearUseCase } from '../application/use-cases/create-academic-year';
import type { ListAcademicYearsUseCase } from '../application/use-cases/list-academic-years';
import type { UpdateAcademicYearUseCase } from '../application/use-cases/update-academic-year';
import type { SetCurrentAcademicYearUseCase } from '../application/use-cases/set-current-academic-year';
import type { CreateCourseUseCase } from '../application/use-cases/create-course';
import type { UpdateCourseUseCase } from '../application/use-cases/update-course';
import type { ListCoursesUseCase } from '../application/use-cases/list-courses';
import type { SoftDeleteCourseUseCase } from '../application/use-cases/soft-delete-course';
import type { CreateDisciplineUseCase } from '../application/use-cases/create-discipline';
import type { UpdateDisciplineUseCase } from '../application/use-cases/update-discipline';
import type { ListDisciplinesUseCase } from '../application/use-cases/list-disciplines';
import type { SoftDeleteDisciplineUseCase } from '../application/use-cases/soft-delete-discipline';
import type { LinkDisciplineToCourseUseCase } from '../application/use-cases/link-discipline-to-course';
import type { UnlinkDisciplineFromCourseUseCase } from '../application/use-cases/unlink-discipline-from-course';
import type { ListCourseDisciplinesUseCase } from '../application/use-cases/list-course-disciplines';
import type { CreateAssessmentPeriodUseCase } from '../application/use-cases/create-assessment-period';
import type { UpdateAssessmentPeriodUseCase } from '../application/use-cases/update-assessment-period';
import type { ListAssessmentPeriodsUseCase } from '../application/use-cases/list-assessment-periods';
import type { ReorderAssessmentPeriodsUseCase } from '../application/use-cases/reorder-assessment-periods';

type IdParams = { id: string };
type CourseIdParams = { courseId: string };
type CourseDisciplineParams = { courseId: string; disciplineId: string };
type AssessmentPeriodsQuery = { academicYearId: string };

/**
 * Adapta HTTP <-> Use Cases do módulo Academic. Nenhuma regra de negócio aqui:
 * apenas leitura de `req.auth`, delegação e formatação da resposta.
 */
export class AcademicController {
  constructor(
    private readonly createAcademicYearUseCase: CreateAcademicYearUseCase,
    private readonly listAcademicYearsUseCase: ListAcademicYearsUseCase,
    private readonly updateAcademicYearUseCase: UpdateAcademicYearUseCase,
    private readonly setCurrentAcademicYearUseCase: SetCurrentAcademicYearUseCase,
    private readonly createCourseUseCase: CreateCourseUseCase,
    private readonly updateCourseUseCase: UpdateCourseUseCase,
    private readonly listCoursesUseCase: ListCoursesUseCase,
    private readonly softDeleteCourseUseCase: SoftDeleteCourseUseCase,
    private readonly createDisciplineUseCase: CreateDisciplineUseCase,
    private readonly updateDisciplineUseCase: UpdateDisciplineUseCase,
    private readonly listDisciplinesUseCase: ListDisciplinesUseCase,
    private readonly softDeleteDisciplineUseCase: SoftDeleteDisciplineUseCase,
    private readonly linkDisciplineToCourseUseCase: LinkDisciplineToCourseUseCase,
    private readonly unlinkDisciplineFromCourseUseCase: UnlinkDisciplineFromCourseUseCase,
    private readonly listCourseDisciplinesUseCase: ListCourseDisciplinesUseCase,
    private readonly createAssessmentPeriodUseCase: CreateAssessmentPeriodUseCase,
    private readonly updateAssessmentPeriodUseCase: UpdateAssessmentPeriodUseCase,
    private readonly listAssessmentPeriodsUseCase: ListAssessmentPeriodsUseCase,
    private readonly reorderAssessmentPeriodsUseCase: ReorderAssessmentPeriodsUseCase,
  ) {}

  // --- Academic years -------------------------------------------------

  createAcademicYear = async (req: Request, res: Response): Promise<void> => {
    const teacherId = req.auth!.teacherId;
    const result = await this.createAcademicYearUseCase.execute({ ...req.body, teacherId });
    res.status(201).json({ data: result });
  };

  listAcademicYears = async (req: Request, res: Response): Promise<void> => {
    const teacherId = req.auth!.teacherId;
    const result = await this.listAcademicYearsUseCase.execute(teacherId);
    res.status(200).json({ data: result });
  };

  updateAcademicYear = async (req: Request<IdParams>, res: Response): Promise<void> => {
    const teacherId = req.auth!.teacherId;
    const result = await this.updateAcademicYearUseCase.execute(teacherId, req.params.id, req.body);
    res.status(200).json({ data: result });
  };

  setCurrentAcademicYear = async (req: Request<IdParams>, res: Response): Promise<void> => {
    const teacherId = req.auth!.teacherId;
    const result = await this.setCurrentAcademicYearUseCase.execute(teacherId, req.params.id);
    res.status(200).json({ data: result });
  };

  // --- Courses ----------------------------------------------------------

  createCourse = async (req: Request, res: Response): Promise<void> => {
    const teacherId = req.auth!.teacherId;
    const result = await this.createCourseUseCase.execute({ ...req.body, teacherId });
    res.status(201).json({ data: result });
  };

  listCourses = async (req: Request, res: Response): Promise<void> => {
    const teacherId = req.auth!.teacherId;
    const result = await this.listCoursesUseCase.execute(teacherId);
    res.status(200).json({ data: result });
  };

  updateCourse = async (req: Request<IdParams>, res: Response): Promise<void> => {
    const teacherId = req.auth!.teacherId;
    const result = await this.updateCourseUseCase.execute(teacherId, req.params.id, req.body);
    res.status(200).json({ data: result });
  };

  softDeleteCourse = async (req: Request<IdParams>, res: Response): Promise<void> => {
    const teacherId = req.auth!.teacherId;
    await this.softDeleteCourseUseCase.execute(teacherId, req.params.id);
    res.status(204).send();
  };

  // --- Disciplines --------------------------------------------------

  createDiscipline = async (req: Request, res: Response): Promise<void> => {
    const teacherId = req.auth!.teacherId;
    const result = await this.createDisciplineUseCase.execute({ ...req.body, teacherId });
    res.status(201).json({ data: result });
  };

  listDisciplines = async (req: Request, res: Response): Promise<void> => {
    const teacherId = req.auth!.teacherId;
    const result = await this.listDisciplinesUseCase.execute(teacherId);
    res.status(200).json({ data: result });
  };

  updateDiscipline = async (req: Request<IdParams>, res: Response): Promise<void> => {
    const teacherId = req.auth!.teacherId;
    const result = await this.updateDisciplineUseCase.execute(teacherId, req.params.id, req.body);
    res.status(200).json({ data: result });
  };

  softDeleteDiscipline = async (req: Request<IdParams>, res: Response): Promise<void> => {
    const teacherId = req.auth!.teacherId;
    await this.softDeleteDisciplineUseCase.execute(teacherId, req.params.id);
    res.status(204).send();
  };

  // --- Course <-> Discipline links --------------------------------------

  listCourseDisciplines = async (req: Request<CourseIdParams>, res: Response): Promise<void> => {
    const teacherId = req.auth!.teacherId;
    const result = await this.listCourseDisciplinesUseCase.execute(teacherId, req.params.courseId);
    res.status(200).json({ data: result });
  };

  linkDisciplineToCourse = async (req: Request<CourseIdParams>, res: Response): Promise<void> => {
    const teacherId = req.auth!.teacherId;
    const result = await this.linkDisciplineToCourseUseCase.execute({
      teacherId,
      courseId: req.params.courseId,
      disciplineId: req.body.disciplineId,
    });
    res.status(201).json({ data: result });
  };

  unlinkDisciplineFromCourse = async (
    req: Request<CourseDisciplineParams>,
    res: Response,
  ): Promise<void> => {
    const teacherId = req.auth!.teacherId;
    await this.unlinkDisciplineFromCourseUseCase.execute(
      teacherId,
      req.params.courseId,
      req.params.disciplineId,
    );
    res.status(204).send();
  };

  // --- Assessment periods -------------------------------------------

  createAssessmentPeriod = async (req: Request, res: Response): Promise<void> => {
    const teacherId = req.auth!.teacherId;
    const result = await this.createAssessmentPeriodUseCase.execute({ ...req.body, teacherId });
    res.status(201).json({ data: result });
  };

  listAssessmentPeriods = async (
    req: Request<ParamsDictionary, unknown, unknown, AssessmentPeriodsQuery>,
    res: Response,
  ): Promise<void> => {
    const teacherId = req.auth!.teacherId;
    const result = await this.listAssessmentPeriodsUseCase.execute(
      teacherId,
      req.query.academicYearId,
    );
    res.status(200).json({ data: result });
  };

  updateAssessmentPeriod = async (req: Request<IdParams>, res: Response): Promise<void> => {
    const teacherId = req.auth!.teacherId;
    const result = await this.updateAssessmentPeriodUseCase.execute(
      teacherId,
      req.params.id,
      req.body,
    );
    res.status(200).json({ data: result });
  };

  reorderAssessmentPeriods = async (req: Request, res: Response): Promise<void> => {
    const teacherId = req.auth!.teacherId;
    const result = await this.reorderAssessmentPeriodsUseCase.execute({ ...req.body, teacherId });
    res.status(200).json({ data: result });
  };
}
