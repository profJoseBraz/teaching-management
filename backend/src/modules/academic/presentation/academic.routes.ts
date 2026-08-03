import { Router } from 'express';
import { asyncHandler } from '../../../shared/http/async-handler';
import type { AuthMiddleware } from '../../../shared/http/auth.middleware';
import { validate } from '../../../shared/http/validate';
import type { AcademicController } from './academic.controller';
import {
  courseDisciplineParamsSchema,
  courseIdParamSchema,
  createAcademicYearSchema,
  createAssessmentPeriodSchema,
  createCourseSchema,
  createDisciplineSchema,
  idParamSchema,
  linkDisciplineToCourseSchema,
  listAssessmentPeriodsQuerySchema,
  reorderAssessmentPeriodsSchema,
  updateAcademicYearSchema,
  updateAssessmentPeriodSchema,
  updateCourseSchema,
  updateDisciplineSchema,
} from './academic.schemas';

export function createAcademicRoutes(
  controller: AcademicController,
  authMiddleware: AuthMiddleware,
): Router {
  const router = Router();

  router.use(authMiddleware);

  router.get('/academic-years', asyncHandler(controller.listAcademicYears));
  router.post(
    '/academic-years',
    validate(createAcademicYearSchema),
    asyncHandler(controller.createAcademicYear),
  );
  router.patch(
    '/academic-years/:id',
    validate(idParamSchema, 'params'),
    validate(updateAcademicYearSchema),
    asyncHandler(controller.updateAcademicYear),
  );
  router.post(
    '/academic-years/:id/set-current',
    validate(idParamSchema, 'params'),
    asyncHandler(controller.setCurrentAcademicYear),
  );

  router.get('/courses', asyncHandler(controller.listCourses));
  router.post('/courses', validate(createCourseSchema), asyncHandler(controller.createCourse));
  router.patch(
    '/courses/:id',
    validate(idParamSchema, 'params'),
    validate(updateCourseSchema),
    asyncHandler(controller.updateCourse),
  );
  router.delete(
    '/courses/:id',
    validate(idParamSchema, 'params'),
    asyncHandler(controller.softDeleteCourse),
  );

  router.get('/disciplines', asyncHandler(controller.listDisciplines));
  router.post(
    '/disciplines',
    validate(createDisciplineSchema),
    asyncHandler(controller.createDiscipline),
  );
  router.patch(
    '/disciplines/:id',
    validate(idParamSchema, 'params'),
    validate(updateDisciplineSchema),
    asyncHandler(controller.updateDiscipline),
  );
  router.delete(
    '/disciplines/:id',
    validate(idParamSchema, 'params'),
    asyncHandler(controller.softDeleteDiscipline),
  );

  router.get(
    '/courses/:courseId/disciplines',
    validate(courseIdParamSchema, 'params'),
    asyncHandler(controller.listCourseDisciplines),
  );
  router.post(
    '/courses/:courseId/disciplines',
    validate(courseIdParamSchema, 'params'),
    validate(linkDisciplineToCourseSchema),
    asyncHandler(controller.linkDisciplineToCourse),
  );
  router.delete(
    '/courses/:courseId/disciplines/:disciplineId',
    validate(courseDisciplineParamsSchema, 'params'),
    asyncHandler(controller.unlinkDisciplineFromCourse),
  );

  router.get(
    '/assessment-periods',
    validate(listAssessmentPeriodsQuerySchema, 'query'),
    asyncHandler(controller.listAssessmentPeriods),
  );
  router.post(
    '/assessment-periods',
    validate(createAssessmentPeriodSchema),
    asyncHandler(controller.createAssessmentPeriod),
  );
  router.patch(
    '/assessment-periods/:id',
    validate(idParamSchema, 'params'),
    validate(updateAssessmentPeriodSchema),
    asyncHandler(controller.updateAssessmentPeriod),
  );
  router.put(
    '/assessment-periods/reorder',
    validate(reorderAssessmentPeriodsSchema),
    asyncHandler(controller.reorderAssessmentPeriods),
  );

  return router;
}
