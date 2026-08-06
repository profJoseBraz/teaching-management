import cors from 'cors';
import express from 'express';
import helmet from 'helmet';
import swaggerUi from 'swagger-ui-express';
import { env } from './config/env';
import type { Container } from './di/container';
import { openApiDocument } from './docs/openapi';
import { createAcademicRoutes } from './modules/academic/presentation/academic.routes';
import { createAgendaRoutes } from './modules/agenda/presentation/agenda.routes';
import { createActivityRoutes } from './modules/activities/presentation/activity.routes';
import { createAttendanceRoutes } from './modules/attendance/presentation/attendance.routes';
import { createClassRoutes } from './modules/classes/presentation/class.routes';
import { createContentRoutes } from './modules/contents/presentation/content.routes';
import { createAuthRoutes } from './modules/identity/presentation/auth.routes';
import { createDashboardRoutes } from './modules/insights/presentation/dashboard.routes';
import { createLessonRoutes } from './modules/lessons/presentation/lesson.routes';
import { createReportsRoutes } from './modules/reports/presentation/reports.routes';
import { createStudentRoutes } from './modules/students/presentation/student.routes';
import { errorHandler } from './shared/http/error-handler';
import { apiRateLimit } from './shared/http/rate-limit';

export function createApp(container: Container) {
  const app = express();

  app.use(helmet());
  app.use(
    cors({
      origin: env.CORS_ORIGIN === '*' ? true : env.CORS_ORIGIN.split(',').map((v) => v.trim()),
    }),
  );
  app.use(express.json({ limit: '1mb' }));
  app.use(apiRateLimit);

  app.use('/api/docs', swaggerUi.serve, swaggerUi.setup(openApiDocument, { explorer: true }));
  app.get('/api/docs.json', (_req, res) => {
    res.json(openApiDocument);
  });

  const api = express.Router();

  api.get('/health', (_req, res) => {
    res.status(200).json({
      data: {
        status: 'ok',
        service: 'gestao-docente-api',
      },
    });
  });

  api.use('/auth', createAuthRoutes(container.authController, container.authMiddleware));

  // Demais rotas já incluem o path completo (ex: /classes, /academic-years),
  // portanto são montadas na raiz do router de API.
  api.use(createAcademicRoutes(container.academicController, container.authMiddleware));
  api.use(createStudentRoutes(container.studentController, container.authMiddleware));
  api.use(createAgendaRoutes(container.agendaController, container.authMiddleware));
  api.use(createClassRoutes(container.classController, container.authMiddleware));
  api.use(createLessonRoutes(container.lessonController, container.authMiddleware));
  api.use(createContentRoutes(container.contentController, container.authMiddleware));
  api.use(createAttendanceRoutes(container.attendanceController, container.authMiddleware));
  api.use(
    createActivityRoutes(
      container.activityController,
      container.submissionController,
      container.authMiddleware,
    ),
  );
  api.use(createDashboardRoutes(container.dashboardController, container.authMiddleware));
  api.use(createReportsRoutes(container.reportsController, container.authMiddleware));

  app.use('/api/v1', api);
  app.use(errorHandler);

  return app;
}
