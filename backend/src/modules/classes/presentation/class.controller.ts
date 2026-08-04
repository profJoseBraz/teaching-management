import type { Request, Response } from 'express';
import type { ParamsDictionary } from 'express-serve-static-core';
import type { CreateClassUseCase } from '../application/use-cases/create-class';
import type { UpdateClassUseCase } from '../application/use-cases/update-class';
import type { ListClassesUseCase } from '../application/use-cases/list-classes';
import type { GetClassUseCase } from '../application/use-cases/get-class';
import type { ArchiveClassUseCase } from '../application/use-cases/archive-class';
import type { BulkEnrollStudentsUseCase } from '../application/use-cases/bulk-enroll-students';
import type { EnrollStudentUseCase } from '../application/use-cases/enroll-student';
import type { UnenrollStudentUseCase } from '../application/use-cases/unenroll-student';
import type { ListClassStudentsUseCase } from '../application/use-cases/list-class-students';
import type { ListClassDisciplinesUseCase } from '../application/use-cases/list-class-disciplines';
import type { LinkDisciplineToClassUseCase } from '../application/use-cases/link-discipline-to-class';
import type { UnlinkDisciplineFromClassUseCase } from '../application/use-cases/unlink-discipline-from-class';
import type { ClassStatus } from '../domain/class';

type IdParams = { id: string };
type ClassIdParams = { classId: string };
type ClassStudentParams = { classId: string; studentId: string };
type ClassDisciplineParams = { classId: string; disciplineId: string };
type ListClassesQuery = {
  academicYearId?: string;
  courseId?: string;
  disciplineId?: string;
  status?: ClassStatus;
};

/** Adapta HTTP <-> Use Cases do módulo Classes. Nenhuma regra de negócio aqui. */
export class ClassController {
  constructor(
    private readonly createClassUseCase: CreateClassUseCase,
    private readonly updateClassUseCase: UpdateClassUseCase,
    private readonly listClassesUseCase: ListClassesUseCase,
    private readonly getClassUseCase: GetClassUseCase,
    private readonly archiveClassUseCase: ArchiveClassUseCase,
    private readonly enrollStudentUseCase: EnrollStudentUseCase,
    private readonly bulkEnrollStudentsUseCase: BulkEnrollStudentsUseCase,
    private readonly unenrollStudentUseCase: UnenrollStudentUseCase,
    private readonly listClassStudentsUseCase: ListClassStudentsUseCase,
    private readonly listClassDisciplinesUseCase: ListClassDisciplinesUseCase,
    private readonly linkDisciplineToClassUseCase: LinkDisciplineToClassUseCase,
    private readonly unlinkDisciplineFromClassUseCase: UnlinkDisciplineFromClassUseCase,
  ) {}

  create = async (req: Request, res: Response): Promise<void> => {
    const teacherId = req.auth!.teacherId;
    const result = await this.createClassUseCase.execute({ ...req.body, teacherId });
    res.status(201).json({ data: result });
  };

  list = async (
    req: Request<ParamsDictionary, unknown, unknown, ListClassesQuery>,
    res: Response,
  ): Promise<void> => {
    const teacherId = req.auth!.teacherId;
    const { academicYearId, courseId, disciplineId, status } = req.query;
    const result = await this.listClassesUseCase.execute(teacherId, {
      academicYearId,
      courseId,
      disciplineId,
      status,
    });
    res.status(200).json({ data: result });
  };

  get = async (req: Request<IdParams>, res: Response): Promise<void> => {
    const teacherId = req.auth!.teacherId;
    const result = await this.getClassUseCase.execute(teacherId, req.params.id);
    res.status(200).json({ data: result });
  };

  update = async (req: Request<IdParams>, res: Response): Promise<void> => {
    const teacherId = req.auth!.teacherId;
    const result = await this.updateClassUseCase.execute(teacherId, req.params.id, req.body);
    res.status(200).json({ data: result });
  };

  archive = async (req: Request<IdParams>, res: Response): Promise<void> => {
    const teacherId = req.auth!.teacherId;
    const result = await this.archiveClassUseCase.execute(teacherId, req.params.id);
    res.status(200).json({ data: result });
  };

  listEnrollments = async (req: Request<ClassIdParams>, res: Response): Promise<void> => {
    const teacherId = req.auth!.teacherId;
    const result = await this.listClassStudentsUseCase.execute(teacherId, req.params.classId);
    res.status(200).json({ data: result });
  };

  enrollStudent = async (req: Request<ClassIdParams>, res: Response): Promise<void> => {
    const teacherId = req.auth!.teacherId;
    const result = await this.enrollStudentUseCase.execute({
      teacherId,
      classId: req.params.classId,
      studentId: req.body.studentId,
    });
    res.status(201).json({ data: result });
  };

  bulkEnrollStudents = async (req: Request<ClassIdParams>, res: Response): Promise<void> => {
    const teacherId = req.auth!.teacherId;
    const result = await this.bulkEnrollStudentsUseCase.execute({
      teacherId,
      classId: req.params.classId,
      studentIds: req.body.studentIds,
    });
    res.status(201).json({ data: result });
  };

  unenrollStudent = async (req: Request<ClassStudentParams>, res: Response): Promise<void> => {
    const teacherId = req.auth!.teacherId;
    await this.unenrollStudentUseCase.execute(teacherId, req.params.classId, req.params.studentId);
    res.status(204).send();
  };

  listDisciplines = async (req: Request<ClassIdParams>, res: Response): Promise<void> => {
    const teacherId = req.auth!.teacherId;
    const result = await this.listClassDisciplinesUseCase.execute(teacherId, req.params.classId);
    res.status(200).json({ data: result });
  };

  linkDiscipline = async (req: Request<ClassIdParams>, res: Response): Promise<void> => {
    const teacherId = req.auth!.teacherId;
    const result = await this.linkDisciplineToClassUseCase.execute({
      teacherId,
      classId: req.params.classId,
      disciplineId: req.body.disciplineId,
    });
    res.status(201).json({ data: result });
  };

  unlinkDiscipline = async (req: Request<ClassDisciplineParams>, res: Response): Promise<void> => {
    const teacherId = req.auth!.teacherId;
    await this.unlinkDisciplineFromClassUseCase.execute(
      teacherId,
      req.params.classId,
      req.params.disciplineId,
    );
    res.status(204).send();
  };
}
