import type { Request, Response } from 'express';
import type { GetCurrentUserUseCase } from '../application/use-cases/get-current-user';
import type { LoginUseCase } from '../application/use-cases/login';
import type { RefreshTokensUseCase } from '../application/use-cases/refresh-tokens';
import type { RegisterTeacherUseCase } from '../application/use-cases/register-teacher';

export class AuthController {
  constructor(
    private readonly loginUseCase: LoginUseCase,
    private readonly registerTeacherUseCase: RegisterTeacherUseCase,
    private readonly getCurrentUserUseCase: GetCurrentUserUseCase,
    private readonly refreshTokensUseCase: RefreshTokensUseCase,
  ) {}

  login = async (req: Request, res: Response): Promise<void> => {
    const result = await this.loginUseCase.execute(req.body);
    res.status(200).json({ data: result });
  };

  register = async (req: Request, res: Response): Promise<void> => {
    const result = await this.registerTeacherUseCase.execute(req.body);
    res.status(201).json({ data: result });
  };

  refresh = async (req: Request, res: Response): Promise<void> => {
    const result = await this.refreshTokensUseCase.execute(req.body);
    res.status(200).json({ data: result });
  };

  me = async (req: Request, res: Response): Promise<void> => {
    const user = await this.getCurrentUserUseCase.execute(req.auth!.userId);
    res.status(200).json({ data: user });
  };
}
