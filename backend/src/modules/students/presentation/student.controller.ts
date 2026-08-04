import type { Request, Response } from 'express';
import type { ParamsDictionary } from 'express-serve-static-core';
import type { BulkCreateStudentsUseCase } from '../application/use-cases/bulk-create-students';
import type { CreateStudentUseCase } from '../application/use-cases/create-student';
import type { UpdateStudentUseCase } from '../application/use-cases/update-student';
import type { ListStudentsUseCase } from '../application/use-cases/list-students';
import type { GetStudentUseCase } from '../application/use-cases/get-student';
import type { SoftDeleteStudentUseCase } from '../application/use-cases/soft-delete-student';

type IdParams = { id: string };
type ListStudentsQuery = { search?: string };

/** Adapta HTTP <-> Use Cases do módulo Students. Nenhuma regra de negócio aqui. */
export class StudentController {
  constructor(
    private readonly createStudentUseCase: CreateStudentUseCase,
    private readonly bulkCreateStudentsUseCase: BulkCreateStudentsUseCase,
    private readonly updateStudentUseCase: UpdateStudentUseCase,
    private readonly listStudentsUseCase: ListStudentsUseCase,
    private readonly getStudentUseCase: GetStudentUseCase,
    private readonly softDeleteStudentUseCase: SoftDeleteStudentUseCase,
  ) {}

  create = async (req: Request, res: Response): Promise<void> => {
    const teacherId = req.auth!.teacherId;
    const result = await this.createStudentUseCase.execute({ ...req.body, teacherId });
    res.status(201).json({ data: result });
  };

  bulkCreate = async (req: Request, res: Response): Promise<void> => {
    const teacherId = req.auth!.teacherId;
    const result = await this.bulkCreateStudentsUseCase.execute({
      teacherId,
      text: req.body.text,
    });
    res.status(201).json({ data: result });
  };

  list = async (
    req: Request<ParamsDictionary, unknown, unknown, ListStudentsQuery>,
    res: Response,
  ): Promise<void> => {
    const teacherId = req.auth!.teacherId;
    const result = await this.listStudentsUseCase.execute(teacherId, { search: req.query.search });
    res.status(200).json({ data: result });
  };

  get = async (req: Request<IdParams>, res: Response): Promise<void> => {
    const teacherId = req.auth!.teacherId;
    const result = await this.getStudentUseCase.execute(teacherId, req.params.id);
    res.status(200).json({ data: result });
  };

  update = async (req: Request<IdParams>, res: Response): Promise<void> => {
    const teacherId = req.auth!.teacherId;
    const result = await this.updateStudentUseCase.execute(teacherId, req.params.id, req.body);
    res.status(200).json({ data: result });
  };

  remove = async (req: Request<IdParams>, res: Response): Promise<void> => {
    const teacherId = req.auth!.teacherId;
    await this.softDeleteStudentUseCase.execute(teacherId, req.params.id);
    res.status(204).send();
  };
}
