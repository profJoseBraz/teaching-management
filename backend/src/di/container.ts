import { DefaultAuthorizationPolicy } from '../shared/application/authorization-policy';
import { createAuthMiddleware } from '../shared/http/auth.middleware';
import { PrismaClassDisciplineGateway } from '../shared/infra/prisma/prisma-class-discipline-gateway';
import { PrismaClassOwnershipChecker } from '../shared/infra/prisma/prisma-class-ownership-checker';
import { PrismaEnrollmentGateway } from '../shared/infra/prisma/prisma-enrollment-gateway';
import { PrismaLessonGateway } from '../shared/infra/prisma/prisma-lesson-gateway';

// --- Identity -------------------------------------------------------------
import { GetCurrentUserUseCase } from '../modules/identity/application/use-cases/get-current-user';
import { LoginUseCase } from '../modules/identity/application/use-cases/login';
import { RegisterTeacherUseCase } from '../modules/identity/application/use-cases/register-teacher';
import { BcryptPasswordHasher } from '../modules/identity/infrastructure/bcrypt-password-hasher';
import { JwtTokenService } from '../modules/identity/infrastructure/jwt-token-service';
import { PrismaUserRepository } from '../modules/identity/infrastructure/prisma-user-repository';
import { AuthController } from '../modules/identity/presentation/auth.controller';

// --- Academic ---------------------------------------------------------------
import { CreateAcademicYearUseCase } from '../modules/academic/application/use-cases/create-academic-year';
import { CreateAssessmentPeriodUseCase } from '../modules/academic/application/use-cases/create-assessment-period';
import { CreateCourseUseCase } from '../modules/academic/application/use-cases/create-course';
import { CreateDisciplineUseCase } from '../modules/academic/application/use-cases/create-discipline';
import { LinkDisciplineToCourseUseCase } from '../modules/academic/application/use-cases/link-discipline-to-course';
import { ListAcademicYearsUseCase } from '../modules/academic/application/use-cases/list-academic-years';
import { ListAssessmentPeriodsUseCase } from '../modules/academic/application/use-cases/list-assessment-periods';
import { ListCourseDisciplinesUseCase } from '../modules/academic/application/use-cases/list-course-disciplines';
import { ListCoursesUseCase } from '../modules/academic/application/use-cases/list-courses';
import { ListDisciplinesUseCase } from '../modules/academic/application/use-cases/list-disciplines';
import { ReorderAssessmentPeriodsUseCase } from '../modules/academic/application/use-cases/reorder-assessment-periods';
import { SetCurrentAcademicYearUseCase } from '../modules/academic/application/use-cases/set-current-academic-year';
import { SoftDeleteCourseUseCase } from '../modules/academic/application/use-cases/soft-delete-course';
import { SoftDeleteDisciplineUseCase } from '../modules/academic/application/use-cases/soft-delete-discipline';
import { UnlinkDisciplineFromCourseUseCase } from '../modules/academic/application/use-cases/unlink-discipline-from-course';
import { UpdateAcademicYearUseCase } from '../modules/academic/application/use-cases/update-academic-year';
import { UpdateAssessmentPeriodUseCase } from '../modules/academic/application/use-cases/update-assessment-period';
import { UpdateCourseUseCase } from '../modules/academic/application/use-cases/update-course';
import { UpdateDisciplineUseCase } from '../modules/academic/application/use-cases/update-discipline';
import { PrismaAcademicYearRepository } from '../modules/academic/infrastructure/prisma-academic-year-repository';
import { PrismaAssessmentPeriodRepository } from '../modules/academic/infrastructure/prisma-assessment-period-repository';
import { PrismaCourseDisciplineRepository } from '../modules/academic/infrastructure/prisma-course-discipline-repository';
import { PrismaCourseRepository } from '../modules/academic/infrastructure/prisma-course-repository';
import { PrismaDisciplineRepository } from '../modules/academic/infrastructure/prisma-discipline-repository';
import { AcademicController } from '../modules/academic/presentation/academic.controller';

// --- Students -----------------------------------------------------------
import { CreateStudentUseCase } from '../modules/students/application/use-cases/create-student';
import { GetStudentUseCase } from '../modules/students/application/use-cases/get-student';
import { ListStudentsUseCase } from '../modules/students/application/use-cases/list-students';
import { SoftDeleteStudentUseCase } from '../modules/students/application/use-cases/soft-delete-student';
import { UpdateStudentUseCase } from '../modules/students/application/use-cases/update-student';
import { BulkCreateStudentsUseCase } from '../modules/students/application/use-cases/bulk-create-students';
import { PrismaStudentRepository } from '../modules/students/infrastructure/prisma-student-repository';
import { StudentController } from '../modules/students/presentation/student.controller';

// --- Classes ------------------------------------------------------------
import { ArchiveClassUseCase } from '../modules/classes/application/use-cases/archive-class';
import { CreateClassUseCase } from '../modules/classes/application/use-cases/create-class';
import { EnrollStudentUseCase } from '../modules/classes/application/use-cases/enroll-student';
import { GetClassUseCase } from '../modules/classes/application/use-cases/get-class';
import { LinkDisciplineToClassUseCase } from '../modules/classes/application/use-cases/link-discipline-to-class';
import { ListClassDisciplinesUseCase } from '../modules/classes/application/use-cases/list-class-disciplines';
import { ListClassStudentsUseCase } from '../modules/classes/application/use-cases/list-class-students';
import { ListClassesUseCase } from '../modules/classes/application/use-cases/list-classes';
import { BulkEnrollStudentsUseCase } from '../modules/classes/application/use-cases/bulk-enroll-students';
import { UnenrollStudentUseCase } from '../modules/classes/application/use-cases/unenroll-student';
import { UnlinkDisciplineFromClassUseCase } from '../modules/classes/application/use-cases/unlink-discipline-from-class';
import { UpdateClassUseCase } from '../modules/classes/application/use-cases/update-class';
import { PrismaClassDisciplineRepository } from '../modules/classes/infrastructure/prisma-class-discipline-repository';
import { PrismaClassRepository } from '../modules/classes/infrastructure/prisma-class-repository';
import { PrismaEnrollmentRepository } from '../modules/classes/infrastructure/prisma-enrollment-repository';
import { ClassController } from '../modules/classes/presentation/class.controller';

// --- Lessons ------------------------------------------------------------
import { CreateLessonUseCase } from '../modules/lessons/application/use-cases/create-lesson';
import { GetLessonUseCase } from '../modules/lessons/application/use-cases/get-lesson';
import { ListLessonsUseCase } from '../modules/lessons/application/use-cases/list-lessons';
import { SoftDeleteLessonUseCase } from '../modules/lessons/application/use-cases/soft-delete-lesson';
import { UpdateLessonUseCase } from '../modules/lessons/application/use-cases/update-lesson';
import { PrismaLessonRepository } from '../modules/lessons/infrastructure/prisma-lesson-repository';
import { LessonController } from '../modules/lessons/presentation/lesson.controller';

// --- Contents -----------------------------------------------------------
import { CompleteContentUseCase } from '../modules/contents/application/use-cases/complete-content';
import { CreateContentUseCase } from '../modules/contents/application/use-cases/create-content';
import { LinkContentToLessonUseCase } from '../modules/contents/application/use-cases/link-content-to-lesson';
import { ListContentsUseCase } from '../modules/contents/application/use-cases/list-contents';
import { ReopenContentUseCase } from '../modules/contents/application/use-cases/reopen-content';
import { UnlinkContentFromLessonUseCase } from '../modules/contents/application/use-cases/unlink-content-from-lesson';
import { UpdateContentUseCase } from '../modules/contents/application/use-cases/update-content';
import { PrismaContentRepository } from '../modules/contents/infrastructure/prisma-content-repository';
import { PrismaLessonContentRepository } from '../modules/contents/infrastructure/prisma-lesson-content-repository';
import { ContentController } from '../modules/contents/presentation/content.controller';

// --- Attendance ---------------------------------------------------------
import { CompleteAttendanceUseCase } from '../modules/attendance/application/use-cases/complete-attendance';
import { GetAttendanceSheetUseCase } from '../modules/attendance/application/use-cases/get-attendance-sheet';
import { SaveAttendanceUseCase } from '../modules/attendance/application/use-cases/save-attendance';
import { PrismaAttendanceRepository } from '../modules/attendance/infrastructure/prisma-attendance-repository';
import { AttendanceController } from '../modules/attendance/presentation/attendance.controller';

// --- Activities -----------------------------------------------------------
import { CreateActivityGroupsUseCase } from '../modules/activities/application/use-cases/create-activity-groups';
import { CreateActivityUseCase } from '../modules/activities/application/use-cases/create-activity';
import { GetActivityUseCase } from '../modules/activities/application/use-cases/get-activity';
import { GradeGroupSharedUseCase } from '../modules/activities/application/use-cases/grade-group-shared';
import { GradeSubmissionUseCase } from '../modules/activities/application/use-cases/grade-submission';
import { ListActivitiesUseCase } from '../modules/activities/application/use-cases/list-activities';
import { ListSubmissionsUseCase } from '../modules/activities/application/use-cases/list-submissions';
import { MarkSubmissionSubmittedUseCase } from '../modules/activities/application/use-cases/mark-submission-submitted';
import { UpdateActivityUseCase } from '../modules/activities/application/use-cases/update-activity';
import { PrismaActivityGroupRepository } from '../modules/activities/infrastructure/prisma-activity-group-repository';
import { PrismaActivityRepository } from '../modules/activities/infrastructure/prisma-activity-repository';
import { PrismaSubmissionRepository } from '../modules/activities/infrastructure/prisma-submission-repository';
import { ActivityController } from '../modules/activities/presentation/activity.controller';
import { SubmissionController } from '../modules/activities/presentation/submission.controller';

// --- Insights (dashboard) -------------------------------------------------
import { GetAttentionItemsUseCase } from '../modules/insights/application/use-cases/get-attention-items';
import { GetDashboardUseCase } from '../modules/insights/application/use-cases/get-dashboard';
import { PrismaInsightsRepository } from '../modules/insights/infrastructure/prisma-insights-repository';
import { DashboardController } from '../modules/insights/presentation/dashboard.controller';

// --- Reports --------------------------------------------------------------
import { RunReportUseCase } from '../modules/reports/application/use-cases/run-report';
import { PrismaReportsRepository } from '../modules/reports/infrastructure/prisma-reports-repository';
import { ReportsController } from '../modules/reports/presentation/reports.controller';

export function createContainer() {
  // --- Shared infrastructure (ports usados por múltiplos módulos) ---------
  const classOwnershipChecker = new PrismaClassOwnershipChecker();
  const lessonGateway = new PrismaLessonGateway();
  const enrollmentGateway = new PrismaEnrollmentGateway();
  const classDisciplineGateway = new PrismaClassDisciplineGateway();
  const authorizationPolicy = new DefaultAuthorizationPolicy();

  // --- Identity -------------------------------------------------------------
  const userRepository = new PrismaUserRepository();
  const passwordHasher = new BcryptPasswordHasher();
  const tokenService = new JwtTokenService();

  const loginUseCase = new LoginUseCase(userRepository, passwordHasher, tokenService);
  const registerTeacherUseCase = new RegisterTeacherUseCase(
    userRepository,
    passwordHasher,
    tokenService,
  );
  const getCurrentUserUseCase = new GetCurrentUserUseCase(userRepository);

  const authController = new AuthController(
    loginUseCase,
    registerTeacherUseCase,
    getCurrentUserUseCase,
  );

  const authMiddleware = createAuthMiddleware(tokenService);

  // --- Academic ---------------------------------------------------------------
  const academicYearRepository = new PrismaAcademicYearRepository();
  const courseRepository = new PrismaCourseRepository();
  const disciplineRepository = new PrismaDisciplineRepository();
  const courseDisciplineRepository = new PrismaCourseDisciplineRepository();
  const assessmentPeriodRepository = new PrismaAssessmentPeriodRepository();

  const createAcademicYearUseCase = new CreateAcademicYearUseCase(academicYearRepository);
  const listAcademicYearsUseCase = new ListAcademicYearsUseCase(academicYearRepository);
  const updateAcademicYearUseCase = new UpdateAcademicYearUseCase(academicYearRepository);
  const setCurrentAcademicYearUseCase = new SetCurrentAcademicYearUseCase(academicYearRepository);

  const createCourseUseCase = new CreateCourseUseCase(courseRepository);
  const updateCourseUseCase = new UpdateCourseUseCase(courseRepository);
  const listCoursesUseCase = new ListCoursesUseCase(courseRepository);
  const softDeleteCourseUseCase = new SoftDeleteCourseUseCase(courseRepository);

  const createDisciplineUseCase = new CreateDisciplineUseCase(disciplineRepository);
  const updateDisciplineUseCase = new UpdateDisciplineUseCase(disciplineRepository);
  const listDisciplinesUseCase = new ListDisciplinesUseCase(disciplineRepository);
  const softDeleteDisciplineUseCase = new SoftDeleteDisciplineUseCase(disciplineRepository);

  const linkDisciplineToCourseUseCase = new LinkDisciplineToCourseUseCase(
    courseDisciplineRepository,
    courseRepository,
    disciplineRepository,
  );
  const unlinkDisciplineFromCourseUseCase = new UnlinkDisciplineFromCourseUseCase(
    courseDisciplineRepository,
  );
  const listCourseDisciplinesUseCase = new ListCourseDisciplinesUseCase(
    courseDisciplineRepository,
    courseRepository,
  );

  const createAssessmentPeriodUseCase = new CreateAssessmentPeriodUseCase(
    assessmentPeriodRepository,
    academicYearRepository,
  );
  const updateAssessmentPeriodUseCase = new UpdateAssessmentPeriodUseCase(
    assessmentPeriodRepository,
  );
  const listAssessmentPeriodsUseCase = new ListAssessmentPeriodsUseCase(
    assessmentPeriodRepository,
    academicYearRepository,
  );
  const reorderAssessmentPeriodsUseCase = new ReorderAssessmentPeriodsUseCase(
    assessmentPeriodRepository,
    academicYearRepository,
  );

  const academicController = new AcademicController(
    createAcademicYearUseCase,
    listAcademicYearsUseCase,
    updateAcademicYearUseCase,
    setCurrentAcademicYearUseCase,
    createCourseUseCase,
    updateCourseUseCase,
    listCoursesUseCase,
    softDeleteCourseUseCase,
    createDisciplineUseCase,
    updateDisciplineUseCase,
    listDisciplinesUseCase,
    softDeleteDisciplineUseCase,
    linkDisciplineToCourseUseCase,
    unlinkDisciplineFromCourseUseCase,
    listCourseDisciplinesUseCase,
    createAssessmentPeriodUseCase,
    updateAssessmentPeriodUseCase,
    listAssessmentPeriodsUseCase,
    reorderAssessmentPeriodsUseCase,
  );

  // --- Students -----------------------------------------------------------
  const studentRepository = new PrismaStudentRepository();

  const createStudentUseCase = new CreateStudentUseCase(studentRepository);
  const bulkCreateStudentsUseCase = new BulkCreateStudentsUseCase(studentRepository);
  const updateStudentUseCase = new UpdateStudentUseCase(studentRepository);
  const listStudentsUseCase = new ListStudentsUseCase(studentRepository);
  const getStudentUseCase = new GetStudentUseCase(studentRepository);
  const softDeleteStudentUseCase = new SoftDeleteStudentUseCase(studentRepository);

  const studentController = new StudentController(
    createStudentUseCase,
    bulkCreateStudentsUseCase,
    updateStudentUseCase,
    listStudentsUseCase,
    getStudentUseCase,
    softDeleteStudentUseCase,
  );

  // --- Classes ------------------------------------------------------------
  const classRepository = new PrismaClassRepository();
  const classDisciplineRepository = new PrismaClassDisciplineRepository();
  const enrollmentRepository = new PrismaEnrollmentRepository();

  const createClassUseCase = new CreateClassUseCase(
    classRepository,
    academicYearRepository,
    courseRepository,
    disciplineRepository,
    classDisciplineRepository,
    courseDisciplineRepository,
  );
  const updateClassUseCase = new UpdateClassUseCase(classRepository, classDisciplineRepository);
  const listClassesUseCase = new ListClassesUseCase(classRepository, classDisciplineRepository);
  const getClassUseCase = new GetClassUseCase(classRepository, classDisciplineRepository);
  const archiveClassUseCase = new ArchiveClassUseCase(classRepository, classDisciplineRepository);
  const enrollStudentUseCase = new EnrollStudentUseCase(
    enrollmentRepository,
    classRepository,
    studentRepository,
  );
  const bulkEnrollStudentsUseCase = new BulkEnrollStudentsUseCase(enrollStudentUseCase);
  const unenrollStudentUseCase = new UnenrollStudentUseCase(enrollmentRepository);
  const listClassStudentsUseCase = new ListClassStudentsUseCase(
    enrollmentRepository,
    classRepository,
  );
  const listClassDisciplinesUseCase = new ListClassDisciplinesUseCase(
    classRepository,
    classDisciplineRepository,
  );
  const linkDisciplineToClassUseCase = new LinkDisciplineToClassUseCase(
    classDisciplineRepository,
    classRepository,
    disciplineRepository,
    courseDisciplineRepository,
  );
  const unlinkDisciplineFromClassUseCase = new UnlinkDisciplineFromClassUseCase(
    classDisciplineRepository,
  );

  const classController = new ClassController(
    createClassUseCase,
    updateClassUseCase,
    listClassesUseCase,
    getClassUseCase,
    archiveClassUseCase,
    enrollStudentUseCase,
    bulkEnrollStudentsUseCase,
    unenrollStudentUseCase,
    listClassStudentsUseCase,
    listClassDisciplinesUseCase,
    linkDisciplineToClassUseCase,
    unlinkDisciplineFromClassUseCase,
  );

  // --- Lessons ------------------------------------------------------------
  const lessonRepository = new PrismaLessonRepository();

  const createLessonUseCase = new CreateLessonUseCase(
    lessonRepository,
    classOwnershipChecker,
    classDisciplineGateway,
  );
  const updateLessonUseCase = new UpdateLessonUseCase(lessonRepository);
  const listLessonsUseCase = new ListLessonsUseCase(lessonRepository, classOwnershipChecker);
  const getLessonUseCase = new GetLessonUseCase(lessonRepository);
  const softDeleteLessonUseCase = new SoftDeleteLessonUseCase(lessonRepository);

  const lessonController = new LessonController(
    createLessonUseCase,
    updateLessonUseCase,
    listLessonsUseCase,
    getLessonUseCase,
    softDeleteLessonUseCase,
  );

  // --- Contents -----------------------------------------------------------
  const contentRepository = new PrismaContentRepository();
  const lessonContentRepository = new PrismaLessonContentRepository();

  const createContentUseCase = new CreateContentUseCase(
    contentRepository,
    classOwnershipChecker,
    classDisciplineGateway,
  );
  const updateContentUseCase = new UpdateContentUseCase(contentRepository);
  const listContentsUseCase = new ListContentsUseCase(contentRepository, classOwnershipChecker);
  const completeContentUseCase = new CompleteContentUseCase(contentRepository);
  const reopenContentUseCase = new ReopenContentUseCase(contentRepository);
  const linkContentToLessonUseCase = new LinkContentToLessonUseCase(
    lessonContentRepository,
    contentRepository,
    lessonGateway,
  );
  const unlinkContentFromLessonUseCase = new UnlinkContentFromLessonUseCase(
    lessonContentRepository,
    contentRepository,
    lessonGateway,
  );

  const contentController = new ContentController(
    createContentUseCase,
    updateContentUseCase,
    listContentsUseCase,
    completeContentUseCase,
    reopenContentUseCase,
    linkContentToLessonUseCase,
    unlinkContentFromLessonUseCase,
  );

  // --- Attendance ---------------------------------------------------------
  const attendanceRepository = new PrismaAttendanceRepository();

  const getAttendanceSheetUseCase = new GetAttendanceSheetUseCase(
    attendanceRepository,
    lessonGateway,
    enrollmentGateway,
  );
  const saveAttendanceUseCase = new SaveAttendanceUseCase(
    attendanceRepository,
    lessonGateway,
    enrollmentGateway,
    getAttendanceSheetUseCase,
  );
  const completeAttendanceUseCase = new CompleteAttendanceUseCase(
    attendanceRepository,
    lessonGateway,
    enrollmentGateway,
    getAttendanceSheetUseCase,
  );

  const attendanceController = new AttendanceController(
    getAttendanceSheetUseCase,
    saveAttendanceUseCase,
    completeAttendanceUseCase,
  );

  // --- Activities -----------------------------------------------------------
  const activityRepository = new PrismaActivityRepository();
  const activityGroupRepository = new PrismaActivityGroupRepository();
  const submissionRepository = new PrismaSubmissionRepository();

  const createActivityUseCase = new CreateActivityUseCase(
    activityRepository,
    submissionRepository,
    classOwnershipChecker,
    lessonGateway,
    enrollmentGateway,
    classDisciplineGateway,
  );
  const updateActivityUseCase = new UpdateActivityUseCase(activityRepository);
  const listActivitiesUseCase = new ListActivitiesUseCase(activityRepository, classOwnershipChecker);
  const getActivityUseCase = new GetActivityUseCase(activityRepository, submissionRepository);
  const createActivityGroupsUseCase = new CreateActivityGroupsUseCase(
    activityRepository,
    activityGroupRepository,
    submissionRepository,
    enrollmentGateway,
  );
  const listSubmissionsUseCase = new ListSubmissionsUseCase(activityRepository, submissionRepository);
  const markSubmissionSubmittedUseCase = new MarkSubmissionSubmittedUseCase(submissionRepository);
  const gradeSubmissionUseCase = new GradeSubmissionUseCase(submissionRepository, activityRepository);
  const gradeGroupSharedUseCase = new GradeGroupSharedUseCase(
    submissionRepository,
    activityRepository,
    activityGroupRepository,
  );

  const activityController = new ActivityController(
    createActivityUseCase,
    updateActivityUseCase,
    listActivitiesUseCase,
    getActivityUseCase,
    createActivityGroupsUseCase,
    listSubmissionsUseCase,
  );
  const submissionController = new SubmissionController(
    markSubmissionSubmittedUseCase,
    gradeSubmissionUseCase,
    gradeGroupSharedUseCase,
  );

  // --- Insights (dashboard) -------------------------------------------------
  const insightsRepository = new PrismaInsightsRepository();

  const getAttentionItemsUseCase = new GetAttentionItemsUseCase(insightsRepository);
  const getDashboardUseCase = new GetDashboardUseCase(getAttentionItemsUseCase);

  const dashboardController = new DashboardController(
    getDashboardUseCase,
    getAttentionItemsUseCase,
  );

  // --- Reports --------------------------------------------------------------
  const reportsRepository = new PrismaReportsRepository();
  const runReportUseCase = new RunReportUseCase(reportsRepository);

  const reportsController = new ReportsController(runReportUseCase);

  return {
    authorizationPolicy,
    authController,
    authMiddleware,
    tokenService,
    passwordHasher,
    userRepository,
    academicController,
    studentController,
    classController,
    lessonController,
    contentController,
    attendanceController,
    activityController,
    submissionController,
    dashboardController,
    reportsController,
  };
}

export type Container = ReturnType<typeof createContainer>;
