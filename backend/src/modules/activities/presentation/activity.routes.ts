import { Router } from 'express';
import { asyncHandler } from '../../../shared/http/async-handler';
import type { AuthMiddleware } from '../../../shared/http/auth.middleware';
import { validate } from '../../../shared/http/validate';
import type { ActivityController } from './activity.controller';
import type { SubmissionController } from './submission.controller';
import {
  activityGroupGradeParamSchema,
  activityGroupsParamSchema,
  activityIdParamSchema,
  classIdParamSchema,
  createActivityGroupsSchema,
  createActivitySchema,
  gradeGroupSharedSchema,
  gradeSubmissionSchema,
  gradeSubmissionsBulkSchema,
  listActivitiesQuerySchema,
  submissionIdParamSchema,
  updateActivitySchema,
  updateSubmissionSchema,
} from './activity.schemas';

/** Rotas devem ser montadas na raiz do router de API (paths já incluem o prefixo completo). */
export function createActivityRoutes(
  activityController: ActivityController,
  submissionController: SubmissionController,
  authMiddleware: AuthMiddleware,
): Router {
  const router = Router();

  router.use(authMiddleware);

  router.get(
    '/classes/:classId/activities',
    validate(classIdParamSchema, 'params'),
    validate(listActivitiesQuerySchema, 'query'),
    asyncHandler(activityController.list),
  );
  router.post(
    '/classes/:classId/activities',
    validate(classIdParamSchema, 'params'),
    validate(createActivitySchema),
    asyncHandler(activityController.create),
  );
  router.get(
    '/activities/:id',
    validate(activityIdParamSchema, 'params'),
    asyncHandler(activityController.get),
  );
  router.patch(
    '/activities/:id',
    validate(activityIdParamSchema, 'params'),
    validate(updateActivitySchema),
    asyncHandler(activityController.update),
  );
  router.delete(
    '/activities/:id',
    validate(activityIdParamSchema, 'params'),
    asyncHandler(activityController.remove),
  );
  router.post(
    '/activities/:id/mark-evaluated',
    validate(activityIdParamSchema, 'params'),
    asyncHandler(activityController.markEvaluated),
  );
  router.post(
    '/activities/:id/reopen-evaluation',
    validate(activityIdParamSchema, 'params'),
    asyncHandler(activityController.reopenEvaluation),
  );
  router.post(
    '/activities/:id/groups',
    validate(activityGroupsParamSchema, 'params'),
    validate(createActivityGroupsSchema),
    asyncHandler(activityController.createGroups),
  );
  router.get(
    '/activities/:id/submissions',
    validate(activityIdParamSchema, 'params'),
    asyncHandler(activityController.listSubmissions),
  );
  router.post(
    '/activities/:id/submissions/grade-bulk',
    validate(activityIdParamSchema, 'params'),
    validate(gradeSubmissionsBulkSchema),
    asyncHandler(submissionController.gradeBulk),
  );

  router.patch(
    '/submissions/:id',
    validate(submissionIdParamSchema, 'params'),
    validate(updateSubmissionSchema),
    asyncHandler(submissionController.update),
  );
  router.post(
    '/submissions/:id/grade',
    validate(submissionIdParamSchema, 'params'),
    validate(gradeSubmissionSchema),
    asyncHandler(submissionController.grade),
  );
  router.post(
    '/activities/:activityId/groups/:groupId/grade-shared',
    validate(activityGroupGradeParamSchema, 'params'),
    validate(gradeGroupSharedSchema),
    asyncHandler(submissionController.gradeGroupShared),
  );

  return router;
}
