import type { Request, Response } from 'express';
import type { ParamsDictionary } from 'express-serve-static-core';
import type { CreateAgendaNoteUseCase } from '../application/use-cases/create-agenda-note';
import type { DeleteAgendaNoteUseCase } from '../application/use-cases/delete-agenda-note';
import type { GetAgendaNoteUseCase } from '../application/use-cases/get-agenda-note';
import type { ListAgendaNotesUseCase } from '../application/use-cases/list-agenda-notes';
import type { UpdateAgendaNoteUseCase } from '../application/use-cases/update-agenda-note';

type IdParams = { id: string };
type ListAgendaQuery = {
  from?: Date;
  to?: Date;
  search?: string;
  completed?: boolean;
};

/** Adapta HTTP <-> Use Cases do módulo Agenda. Nenhuma regra de negócio aqui. */
export class AgendaController {
  constructor(
    private readonly createAgendaNoteUseCase: CreateAgendaNoteUseCase,
    private readonly updateAgendaNoteUseCase: UpdateAgendaNoteUseCase,
    private readonly listAgendaNotesUseCase: ListAgendaNotesUseCase,
    private readonly getAgendaNoteUseCase: GetAgendaNoteUseCase,
    private readonly deleteAgendaNoteUseCase: DeleteAgendaNoteUseCase,
  ) {}

  create = async (req: Request, res: Response): Promise<void> => {
    const teacherId = req.auth!.teacherId;
    const result = await this.createAgendaNoteUseCase.execute({
      teacherId,
      date: new Date(req.body.date),
      content: req.body.content,
      completed: req.body.completed,
    });
    res.status(201).json({ data: result });
  };

  list = async (
    req: Request<ParamsDictionary, unknown, unknown, ListAgendaQuery>,
    res: Response,
  ): Promise<void> => {
    const teacherId = req.auth!.teacherId;
    const result = await this.listAgendaNotesUseCase.execute(teacherId, {
      from: req.query.from ? new Date(req.query.from) : undefined,
      to: req.query.to ? new Date(req.query.to) : undefined,
      search: req.query.search,
      completed: req.query.completed,
    });
    res.status(200).json({ data: result });
  };

  get = async (req: Request<IdParams>, res: Response): Promise<void> => {
    const teacherId = req.auth!.teacherId;
    const result = await this.getAgendaNoteUseCase.execute(teacherId, req.params.id);
    res.status(200).json({ data: result });
  };

  update = async (req: Request<IdParams>, res: Response): Promise<void> => {
    const teacherId = req.auth!.teacherId;
    const result = await this.updateAgendaNoteUseCase.execute(teacherId, req.params.id, {
      ...(req.body.date !== undefined ? { date: new Date(req.body.date) } : {}),
      ...(req.body.content !== undefined ? { content: req.body.content } : {}),
      ...(req.body.completed !== undefined ? { completed: Boolean(req.body.completed) } : {}),
    });
    res.status(200).json({ data: result });
  };

  remove = async (req: Request<IdParams>, res: Response): Promise<void> => {
    const teacherId = req.auth!.teacherId;
    await this.deleteAgendaNoteUseCase.execute(teacherId, req.params.id);
    res.status(204).send();
  };
}
