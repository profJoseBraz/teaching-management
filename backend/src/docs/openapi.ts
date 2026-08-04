export const openApiDocument = {
  openapi: '3.0.3',
  info: {
    title: 'Gestão Docente API',
    version: '0.1.0',
    description:
      'API REST do Gestão Docente — assistente da rotina do professor. ' +
      'Todos os recursos de negócio são isolados por professor (teacherId do JWT).',
  },
  servers: [{ url: '/api/v1', description: 'API v1' }],
  tags: [
    { name: 'Health' },
    { name: 'Auth' },
    { name: 'Academic Years' },
    { name: 'Courses' },
    { name: 'Disciplines' },
    { name: 'Assessment Periods' },
    { name: 'Students' },
    { name: 'Classes' },
    { name: 'Lessons' },
    { name: 'Contents' },
    { name: 'Attendance' },
    { name: 'Activities' },
    { name: 'Submissions' },
    { name: 'Dashboard' },
    { name: 'Reports' },
  ],
  components: {
    securitySchemes: {
      bearerAuth: {
        type: 'http',
        scheme: 'bearer',
        bearerFormat: 'JWT',
      },
    },
    schemas: {
      Error: {
        type: 'object',
        required: ['error'],
        properties: {
          error: {
            type: 'object',
            required: ['code', 'message'],
            properties: {
              code: { type: 'string' },
              message: { type: 'string' },
              details: {},
            },
          },
        },
      },
      PublicUser: {
        type: 'object',
        properties: {
          id: { type: 'string', format: 'uuid' },
          name: { type: 'string' },
          email: { type: 'string', format: 'email' },
          role: {
            type: 'string',
            enum: ['PROFESSOR', 'ADMIN', 'COORDINATOR', 'SECRETARY'],
          },
          isActive: { type: 'boolean' },
          createdAt: { type: 'string', format: 'date-time' },
          updatedAt: { type: 'string', format: 'date-time' },
          deletedAt: { type: 'string', format: 'date-time', nullable: true },
        },
      },
      TokenPair: {
        type: 'object',
        properties: {
          accessToken: { type: 'string' },
          refreshToken: { type: 'string' },
          expiresIn: { type: 'string', example: '15m' },
        },
      },
      LoginRequest: {
        type: 'object',
        required: ['email', 'password'],
        properties: {
          email: { type: 'string', format: 'email' },
          password: { type: 'string' },
        },
      },
      RegisterRequest: {
        type: 'object',
        required: ['name', 'email', 'password'],
        properties: {
          name: { type: 'string', minLength: 2, maxLength: 120 },
          email: { type: 'string', format: 'email' },
          password: {
            type: 'string',
            minLength: 8,
            description: 'Mín. 8 chars com maiúscula, minúscula e número',
          },
        },
      },
      AuthResponse: {
        type: 'object',
        properties: {
          data: {
            type: 'object',
            properties: {
              user: { $ref: '#/components/schemas/PublicUser' },
              tokens: { $ref: '#/components/schemas/TokenPair' },
            },
          },
        },
      },
      AttentionItem: {
        type: 'object',
        description: 'Pendência acionável do Dashboard — Insights Engine (docs/ARCHITECTURE.md §9)',
        properties: {
          id: { type: 'string' },
          type: {
            type: 'string',
            enum: [
              'LESSONS_WITHOUT_ATTENDANCE',
              'OVERDUE_UNGRADED_ACTIVITIES',
              'ACTIVITIES_AWAITING_GRADE',
              'CONTENTS_IN_PROGRESS',
              'STUDENTS_PENDING_SUBMISSION',
              'ABSENT_ON_ACTIVITY_LESSON',
              'EXCESS_ABSENCES',
              'ACTIVITIES_WITHOUT_SCORE',
            ],
          },
          severity: { type: 'string', enum: ['high', 'medium', 'low'] },
          title: { type: 'string' },
          message: { type: 'string' },
          count: { type: 'integer' },
          actionRoute: { type: 'string' },
          filters: { type: 'object', additionalProperties: true },
        },
      },
      DashboardSummary: {
        type: 'object',
        properties: {
          totalAttentionItems: { type: 'integer' },
          totalPendingActions: { type: 'integer' },
          bySeverity: {
            type: 'object',
            properties: {
              high: { type: 'integer' },
              medium: { type: 'integer' },
              low: { type: 'integer' },
            },
          },
        },
      },
      DashboardResponse: {
        type: 'object',
        properties: {
          attentionItems: { type: 'array', items: { $ref: '#/components/schemas/AttentionItem' } },
          summary: { $ref: '#/components/schemas/DashboardSummary' },
        },
      },
      AttentionItemsResponse: {
        type: 'object',
        properties: {
          attentionItems: { type: 'array', items: { $ref: '#/components/schemas/AttentionItem' } },
        },
      },
      ReportResult: {
        type: 'object',
        description: 'Resultado de execução de um relatório filtrável (docs/ARCHITECTURE.md §17)',
        properties: {
          reportType: { type: 'string' },
          filters: { type: 'object', additionalProperties: true },
          generatedAt: { type: 'string', format: 'date-time' },
          rows: { type: 'array', items: { type: 'object', additionalProperties: true } },
          totalRows: { type: 'integer' },
        },
      },
      AcademicYear: {
        type: 'object',
        properties: {
          id: { type: 'string', format: 'uuid' },
          year: { type: 'integer', example: 2026 },
          label: { type: 'string', nullable: true },
          isCurrent: { type: 'boolean' },
          startsOn: { type: 'string', format: 'date', nullable: true },
          endsOn: { type: 'string', format: 'date', nullable: true },
        },
      },
      CreateAcademicYearRequest: {
        type: 'object',
        required: ['year'],
        properties: {
          year: { type: 'integer', example: 2026 },
          label: { type: 'string', nullable: true },
          startsOn: { type: 'string', format: 'date' },
          endsOn: { type: 'string', format: 'date' },
        },
      },
      UpdateAcademicYearRequest: {
        type: 'object',
        properties: {
          label: { type: 'string', nullable: true },
          startsOn: { type: 'string', format: 'date', nullable: true },
          endsOn: { type: 'string', format: 'date', nullable: true },
        },
      },
      Course: {
        type: 'object',
        properties: {
          id: { type: 'string', format: 'uuid' },
          name: { type: 'string' },
          description: { type: 'string', nullable: true },
        },
      },
      CreateCourseRequest: {
        type: 'object',
        required: ['name'],
        properties: {
          name: { type: 'string' },
          description: { type: 'string' },
        },
      },
      UpdateCourseRequest: {
        type: 'object',
        properties: {
          name: { type: 'string' },
          description: { type: 'string', nullable: true },
        },
      },
      Discipline: {
        type: 'object',
        properties: {
          id: { type: 'string', format: 'uuid' },
          name: { type: 'string' },
          description: { type: 'string', nullable: true },
        },
      },
      CreateDisciplineRequest: {
        type: 'object',
        required: ['name'],
        properties: {
          name: { type: 'string' },
          description: { type: 'string' },
        },
      },
      UpdateDisciplineRequest: {
        type: 'object',
        properties: {
          name: { type: 'string' },
          description: { type: 'string', nullable: true },
        },
      },
      CourseDiscipline: {
        type: 'object',
        properties: {
          id: { type: 'string', format: 'uuid' },
          courseId: { type: 'string', format: 'uuid' },
          disciplineId: { type: 'string', format: 'uuid' },
          discipline: { $ref: '#/components/schemas/Discipline' },
        },
      },
      LinkDisciplineToCourseRequest: {
        type: 'object',
        required: ['disciplineId'],
        properties: {
          disciplineId: { type: 'string', format: 'uuid' },
        },
      },
      AssessmentPeriod: {
        type: 'object',
        properties: {
          id: { type: 'string', format: 'uuid' },
          academicYearId: { type: 'string', format: 'uuid' },
          classId: { type: 'string', format: 'uuid', nullable: true },
          name: { type: 'string', example: '1º Bimestre' },
          sortOrder: { type: 'integer' },
          startsOn: { type: 'string', format: 'date', nullable: true },
          endsOn: { type: 'string', format: 'date', nullable: true },
        },
      },
      CreateAssessmentPeriodRequest: {
        type: 'object',
        required: ['academicYearId', 'name'],
        properties: {
          academicYearId: { type: 'string', format: 'uuid' },
          classId: { type: 'string', format: 'uuid' },
          name: { type: 'string', example: '1º Bimestre' },
          startsOn: { type: 'string', format: 'date' },
          endsOn: { type: 'string', format: 'date' },
        },
      },
      UpdateAssessmentPeriodRequest: {
        type: 'object',
        properties: {
          name: { type: 'string' },
          classId: { type: 'string', format: 'uuid', nullable: true },
          startsOn: { type: 'string', format: 'date', nullable: true },
          endsOn: { type: 'string', format: 'date', nullable: true },
        },
      },
      ReorderAssessmentPeriodsRequest: {
        type: 'object',
        required: ['academicYearId', 'orderedIds'],
        properties: {
          academicYearId: { type: 'string', format: 'uuid' },
          orderedIds: {
            type: 'array',
            items: { type: 'string', format: 'uuid' },
          },
        },
      },
      Class: {
        type: 'object',
        description:
          'Uma turma pode ministrar N disciplinas simultaneamente (docs/ARCHITECTURE.md — Class/ClassDiscipline).',
        properties: {
          id: { type: 'string', format: 'uuid' },
          academicYearId: { type: 'string', format: 'uuid' },
          courseId: { type: 'string', format: 'uuid' },
          name: { type: 'string' },
          shift: {
            type: 'string',
            enum: ['MORNING', 'AFTERNOON', 'EVENING', 'NIGHT'],
            nullable: true,
          },
          status: { type: 'string', enum: ['ACTIVE', 'ARCHIVED'] },
          disciplineIds: { type: 'array', items: { type: 'string', format: 'uuid' } },
          disciplines: {
            type: 'array',
            items: {
              type: 'object',
              properties: {
                id: { type: 'string', format: 'uuid' },
                name: { type: 'string' },
              },
            },
          },
        },
      },
      CreateClassRequest: {
        type: 'object',
        required: ['academicYearId', 'courseId', 'name', 'disciplineIds'],
        properties: {
          academicYearId: { type: 'string', format: 'uuid' },
          courseId: { type: 'string', format: 'uuid' },
          name: { type: 'string', example: '3º DS - Manhã' },
          shift: { type: 'string', enum: ['MORNING', 'AFTERNOON', 'EVENING', 'NIGHT'] },
          disciplineIds: {
            type: 'array',
            items: { type: 'string', format: 'uuid' },
            minItems: 1,
            description: 'Forma preferida — ao menos uma disciplina é obrigatória.',
          },
          disciplineId: {
            type: 'string',
            format: 'uuid',
            deprecated: true,
            description: 'Legado — aceito por compatibilidade e normalizado em `disciplineIds`.',
          },
        },
      },
      UpdateClassRequest: {
        type: 'object',
        properties: {
          name: { type: 'string' },
          shift: {
            type: 'string',
            enum: ['MORNING', 'AFTERNOON', 'EVENING', 'NIGHT'],
            nullable: true,
          },
        },
      },
      ClassDiscipline: {
        type: 'object',
        properties: {
          id: { type: 'string', format: 'uuid' },
          classId: { type: 'string', format: 'uuid' },
          disciplineId: { type: 'string', format: 'uuid' },
          discipline: { $ref: '#/components/schemas/Discipline' },
        },
      },
      LinkDisciplineToClassRequest: {
        type: 'object',
        required: ['disciplineId'],
        properties: {
          disciplineId: { type: 'string', format: 'uuid' },
        },
      },
      Enrollment: {
        type: 'object',
        properties: {
          id: { type: 'string', format: 'uuid' },
          classId: { type: 'string', format: 'uuid' },
          studentId: { type: 'string', format: 'uuid' },
          status: { type: 'string', enum: ['ACTIVE', 'WITHDRAWN'] },
          student: { $ref: '#/components/schemas/Student' },
        },
      },
      EnrollStudentRequest: {
        type: 'object',
        required: ['studentId'],
        properties: {
          studentId: { type: 'string', format: 'uuid' },
        },
      },
      BulkEnrollStudentsRequest: {
        type: 'object',
        required: ['studentIds'],
        properties: {
          studentIds: {
            type: 'array',
            minItems: 1,
            maxItems: 500,
            items: { type: 'string', format: 'uuid' },
          },
        },
      },
      BulkEnrollStudentsResponse: {
        type: 'object',
        properties: {
          enrolled: { type: 'array', items: { $ref: '#/components/schemas/Enrollment' } },
          skipped: {
            type: 'array',
            items: {
              type: 'object',
              properties: {
                studentId: { type: 'string', format: 'uuid' },
                reason: { type: 'string' },
              },
            },
          },
          totalEnrolled: { type: 'integer' },
        },
      },
      Student: {
        type: 'object',
        properties: {
          id: { type: 'string', format: 'uuid' },
          name: { type: 'string' },
          registryCode: { type: 'string', nullable: true },
          email: { type: 'string', nullable: true },
          phone: { type: 'string', nullable: true },
          notes: { type: 'string', nullable: true },
        },
      },
      CreateStudentRequest: {
        type: 'object',
        required: ['name'],
        properties: {
          name: { type: 'string' },
          registryCode: { type: 'string' },
          email: { type: 'string', format: 'email' },
          phone: { type: 'string' },
          notes: { type: 'string' },
        },
      },
      UpdateStudentRequest: {
        type: 'object',
        properties: {
          name: { type: 'string' },
          registryCode: { type: 'string', nullable: true },
          email: { type: 'string', format: 'email', nullable: true },
          phone: { type: 'string', nullable: true },
          notes: { type: 'string', nullable: true },
        },
      },
      Lesson: {
        type: 'object',
        properties: {
          id: { type: 'string', format: 'uuid' },
          classId: { type: 'string', format: 'uuid' },
          disciplineId: { type: 'string', format: 'uuid' },
          date: { type: 'string', format: 'date' },
          startTime: { type: 'string', example: '08:00' },
          endTime: { type: 'string', example: '09:40' },
          observations: { type: 'string', nullable: true },
          attendanceCompleted: { type: 'boolean' },
        },
      },
      Content: {
        type: 'object',
        properties: {
          id: { type: 'string', format: 'uuid' },
          classId: { type: 'string', format: 'uuid' },
          disciplineId: { type: 'string', format: 'uuid' },
          title: { type: 'string' },
          description: { type: 'string', nullable: true },
          status: { type: 'string', enum: ['IN_PROGRESS', 'COMPLETED'] },
          startedAt: { type: 'string', format: 'date-time' },
          completedAt: { type: 'string', format: 'date-time', nullable: true },
        },
      },
      Attendance: {
        type: 'object',
        properties: {
          studentId: { type: 'string', format: 'uuid' },
          status: { type: 'string', enum: ['PRESENT', 'ABSENT', 'LATE'] },
          observations: { type: 'string', nullable: true },
        },
      },
      Activity: {
        type: 'object',
        properties: {
          id: { type: 'string', format: 'uuid' },
          classId: { type: 'string', format: 'uuid' },
          disciplineId: { type: 'string', format: 'uuid' },
          originLessonId: { type: 'string', format: 'uuid' },
          assessmentPeriodId: { type: 'string', format: 'uuid', nullable: true },
          title: { type: 'string' },
          description: { type: 'string', nullable: true },
          category: {
            type: 'string',
            enum: ['EXERCISE', 'ASSIGNMENT', 'PROJECT', 'RESEARCH', 'SEMINAR', 'EXAM', 'OTHER'],
          },
          mode: { type: 'string', enum: ['INDIVIDUAL', 'GROUP'] },
          gradeMode: { type: 'string', enum: ['SHARED', 'INDIVIDUAL'] },
          maxScore: { type: 'number', example: 100 },
          createdOn: { type: 'string', format: 'date' },
          dueDate: { type: 'string', format: 'date' },
        },
      },
      Submission: {
        type: 'object',
        properties: {
          id: { type: 'string', format: 'uuid' },
          activityId: { type: 'string', format: 'uuid' },
          studentId: { type: 'string', format: 'uuid' },
          groupId: { type: 'string', format: 'uuid', nullable: true },
          status: { type: 'string', enum: ['PENDING', 'SUBMITTED', 'GRADED'] },
          score: { type: 'number', nullable: true },
          observations: { type: 'string', nullable: true },
        },
      },
      ActivityGroup: {
        type: 'object',
        properties: {
          id: { type: 'string', format: 'uuid' },
          activityId: { type: 'string', format: 'uuid' },
          name: { type: 'string' },
          studentIds: { type: 'array', items: { type: 'string', format: 'uuid' } },
        },
      },
      AttendanceSheetEntry: {
        type: 'object',
        properties: {
          studentId: { type: 'string', format: 'uuid' },
          studentName: { type: 'string' },
          status: { type: 'string', enum: ['PRESENT', 'ABSENT', 'LATE'], nullable: true },
          observations: { type: 'string', nullable: true },
        },
      },
      AttendanceSheet: {
        type: 'object',
        properties: {
          lessonId: { type: 'string', format: 'uuid' },
          classId: { type: 'string', format: 'uuid' },
          attendanceCompleted: { type: 'boolean' },
          students: { type: 'array', items: { $ref: '#/components/schemas/AttendanceSheetEntry' } },
        },
      },
      CreateLessonRequest: {
        type: 'object',
        required: ['disciplineId', 'date', 'startTime', 'endTime'],
        properties: {
          disciplineId: {
            type: 'string',
            format: 'uuid',
            description: 'Deve estar vinculada à turma (ClassDiscipline ativo).',
          },
          date: { type: 'string', format: 'date' },
          startTime: { type: 'string', example: '08:00' },
          endTime: { type: 'string', example: '09:40' },
          observations: { type: 'string', nullable: true },
        },
      },
      UpdateLessonRequest: {
        type: 'object',
        properties: {
          date: { type: 'string', format: 'date' },
          startTime: { type: 'string', example: '08:00' },
          endTime: { type: 'string', example: '09:40' },
          observations: { type: 'string', nullable: true },
        },
      },
      CreateContentRequest: {
        type: 'object',
        required: ['disciplineId', 'title'],
        properties: {
          disciplineId: {
            type: 'string',
            format: 'uuid',
            description: 'Deve estar vinculada à turma (ClassDiscipline ativo).',
          },
          title: { type: 'string' },
          description: { type: 'string', nullable: true },
        },
      },
      UpdateContentRequest: {
        type: 'object',
        properties: {
          title: { type: 'string' },
          description: { type: 'string', nullable: true },
        },
      },
      LinkContentToLessonRequest: {
        type: 'object',
        required: ['contentId'],
        properties: {
          contentId: { type: 'string', format: 'uuid' },
        },
      },
      SaveAttendanceRequest: {
        type: 'object',
        required: ['records'],
        properties: {
          records: {
            type: 'array',
            items: {
              type: 'object',
              required: ['studentId', 'status'],
              properties: {
                studentId: { type: 'string', format: 'uuid' },
                status: { type: 'string', enum: ['PRESENT', 'ABSENT', 'LATE'] },
                observations: { type: 'string', nullable: true },
              },
            },
          },
        },
      },
      CreateActivityRequest: {
        type: 'object',
        required: ['originLessonId', 'title', 'dueDate'],
        properties: {
          originLessonId: { type: 'string', format: 'uuid' },
          disciplineId: {
            type: 'string',
            format: 'uuid',
            description:
              'Opcional — quando ausente, herda a disciplina de `originLessonId`. Quando informado, deve coincidir com a disciplina da aula de origem e estar vinculado à turma.',
          },
          assessmentPeriodId: { type: 'string', format: 'uuid', nullable: true },
          title: { type: 'string' },
          description: { type: 'string', nullable: true },
          category: {
            type: 'string',
            enum: ['EXERCISE', 'ASSIGNMENT', 'PROJECT', 'RESEARCH', 'SEMINAR', 'EXAM', 'OTHER'],
            default: 'ASSIGNMENT',
          },
          mode: { type: 'string', enum: ['INDIVIDUAL', 'GROUP'], default: 'INDIVIDUAL' },
          gradeMode: { type: 'string', enum: ['SHARED', 'INDIVIDUAL'], default: 'INDIVIDUAL' },
          maxScore: { type: 'number', default: 100 },
          dueDate: { type: 'string', format: 'date' },
        },
      },
      UpdateActivityRequest: {
        type: 'object',
        properties: {
          assessmentPeriodId: { type: 'string', format: 'uuid', nullable: true },
          title: { type: 'string' },
          description: { type: 'string', nullable: true },
          category: {
            type: 'string',
            enum: ['EXERCISE', 'ASSIGNMENT', 'PROJECT', 'RESEARCH', 'SEMINAR', 'EXAM', 'OTHER'],
          },
          mode: { type: 'string', enum: ['INDIVIDUAL', 'GROUP'] },
          gradeMode: { type: 'string', enum: ['SHARED', 'INDIVIDUAL'] },
          maxScore: { type: 'number' },
          dueDate: { type: 'string', format: 'date' },
        },
      },
      GetActivityResponse: {
        type: 'object',
        properties: {
          activity: { $ref: '#/components/schemas/Activity' },
          submissions: { type: 'array', items: { $ref: '#/components/schemas/Submission' } },
          summary: {
            type: 'object',
            properties: {
              total: { type: 'integer' },
              pending: { type: 'integer' },
              submitted: { type: 'integer' },
              graded: { type: 'integer' },
              averageScore: { type: 'number', nullable: true },
            },
          },
        },
      },
      CreateActivityGroupsRequest: {
        type: 'object',
        required: ['groups'],
        properties: {
          groups: {
            type: 'array',
            items: {
              type: 'object',
              required: ['name', 'studentIds'],
              properties: {
                name: { type: 'string' },
                studentIds: { type: 'array', items: { type: 'string', format: 'uuid' } },
              },
            },
          },
        },
      },
      UpdateSubmissionRequest: {
        type: 'object',
        required: ['status'],
        properties: {
          status: { type: 'string', enum: ['SUBMITTED'] },
        },
      },
      GradeSubmissionRequest: {
        type: 'object',
        required: ['score'],
        properties: {
          score: { type: 'number' },
          observations: { type: 'string', nullable: true },
        },
      },
    },
  },
  paths: {
    '/health': {
      get: {
        tags: ['Health'],
        summary: 'Health check',
        responses: {
          '200': {
            description: 'API healthy',
            content: {
              'application/json': {
                schema: {
                  type: 'object',
                  properties: {
                    data: {
                      type: 'object',
                      properties: {
                        status: { type: 'string', example: 'ok' },
                        service: { type: 'string', example: 'gestao-docente-api' },
                      },
                    },
                  },
                },
              },
            },
          },
        },
      },
    },
    '/auth/login': {
      post: {
        tags: ['Auth'],
        summary: 'Login do professor',
        requestBody: {
          required: true,
          content: {
            'application/json': {
              schema: { $ref: '#/components/schemas/LoginRequest' },
            },
          },
        },
        responses: {
          '200': {
            description: 'Autenticado',
            content: {
              'application/json': {
                schema: { $ref: '#/components/schemas/AuthResponse' },
              },
            },
          },
          '401': {
            description: 'Credenciais inválidas',
            content: { 'application/json': { schema: { $ref: '#/components/schemas/Error' } } },
          },
        },
      },
    },
    '/auth/register': {
      post: {
        tags: ['Auth'],
        summary: 'Registrar professor',
        requestBody: {
          required: true,
          content: {
            'application/json': {
              schema: { $ref: '#/components/schemas/RegisterRequest' },
            },
          },
        },
        responses: {
          '201': {
            description: 'Professor criado',
            content: {
              'application/json': {
                schema: { $ref: '#/components/schemas/AuthResponse' },
              },
            },
          },
          '409': {
            description: 'E-mail já cadastrado',
            content: { 'application/json': { schema: { $ref: '#/components/schemas/Error' } } },
          },
        },
      },
    },
    '/auth/me': {
      get: {
        tags: ['Auth'],
        summary: 'Usuário autenticado',
        security: [{ bearerAuth: [] }],
        responses: {
          '200': {
            description: 'Perfil',
            content: {
              'application/json': {
                schema: {
                  type: 'object',
                  properties: {
                    data: { $ref: '#/components/schemas/PublicUser' },
                  },
                },
              },
            },
          },
          '401': {
            description: 'Não autenticado',
            content: { 'application/json': { schema: { $ref: '#/components/schemas/Error' } } },
          },
        },
      },
    },
    '/academic-years': {
      get: {
        tags: ['Academic Years'],
        summary: 'Listar anos letivos do professor autenticado',
        security: [{ bearerAuth: [] }],
        responses: {
          '200': {
            description: 'Lista de anos letivos',
            content: {
              'application/json': {
                schema: {
                  type: 'object',
                  properties: {
                    data: { type: 'array', items: { $ref: '#/components/schemas/AcademicYear' } },
                  },
                },
              },
            },
          },
        },
      },
      post: {
        tags: ['Academic Years'],
        summary: 'Criar ano letivo',
        security: [{ bearerAuth: [] }],
        requestBody: {
          required: true,
          content: {
            'application/json': { schema: { $ref: '#/components/schemas/CreateAcademicYearRequest' } },
          },
        },
        responses: {
          '201': {
            description: 'Ano letivo criado',
            content: {
              'application/json': {
                schema: {
                  type: 'object',
                  properties: { data: { $ref: '#/components/schemas/AcademicYear' } },
                },
              },
            },
          },
          '409': {
            description: 'Já existe um ano letivo com este ano para o professor',
            content: { 'application/json': { schema: { $ref: '#/components/schemas/Error' } } },
          },
        },
      },
    },
    '/academic-years/{id}': {
      patch: {
        tags: ['Academic Years'],
        summary: 'Atualizar ano letivo',
        security: [{ bearerAuth: [] }],
        parameters: [{ name: 'id', in: 'path', required: true, schema: { type: 'string', format: 'uuid' } }],
        requestBody: {
          required: true,
          content: {
            'application/json': { schema: { $ref: '#/components/schemas/UpdateAcademicYearRequest' } },
          },
        },
        responses: {
          '200': {
            description: 'Ano letivo atualizado',
            content: {
              'application/json': {
                schema: {
                  type: 'object',
                  properties: { data: { $ref: '#/components/schemas/AcademicYear' } },
                },
              },
            },
          },
          '404': {
            description: 'Ano letivo não encontrado',
            content: { 'application/json': { schema: { $ref: '#/components/schemas/Error' } } },
          },
        },
      },
    },
    '/academic-years/{id}/set-current': {
      post: {
        tags: ['Academic Years'],
        summary: 'Marcar ano letivo como atual (desmarca os demais)',
        security: [{ bearerAuth: [] }],
        parameters: [{ name: 'id', in: 'path', required: true, schema: { type: 'string', format: 'uuid' } }],
        responses: {
          '200': {
            description: 'Ano letivo marcado como atual',
            content: {
              'application/json': {
                schema: {
                  type: 'object',
                  properties: { data: { $ref: '#/components/schemas/AcademicYear' } },
                },
              },
            },
          },
          '404': {
            description: 'Ano letivo não encontrado',
            content: { 'application/json': { schema: { $ref: '#/components/schemas/Error' } } },
          },
        },
      },
    },
    '/courses': {
      get: {
        tags: ['Courses'],
        summary: 'Listar cursos do professor',
        security: [{ bearerAuth: [] }],
        responses: {
          '200': {
            description: 'Lista de cursos',
            content: {
              'application/json': {
                schema: {
                  type: 'object',
                  properties: { data: { type: 'array', items: { $ref: '#/components/schemas/Course' } } },
                },
              },
            },
          },
        },
      },
      post: {
        tags: ['Courses'],
        summary: 'Criar curso',
        security: [{ bearerAuth: [] }],
        requestBody: {
          required: true,
          content: { 'application/json': { schema: { $ref: '#/components/schemas/CreateCourseRequest' } } },
        },
        responses: {
          '201': {
            description: 'Curso criado',
            content: {
              'application/json': {
                schema: { type: 'object', properties: { data: { $ref: '#/components/schemas/Course' } } },
              },
            },
          },
          '409': {
            description: 'Já existe um curso com este nome para o professor',
            content: { 'application/json': { schema: { $ref: '#/components/schemas/Error' } } },
          },
        },
      },
    },
    '/courses/{id}': {
      patch: {
        tags: ['Courses'],
        summary: 'Atualizar curso',
        security: [{ bearerAuth: [] }],
        parameters: [{ name: 'id', in: 'path', required: true, schema: { type: 'string', format: 'uuid' } }],
        requestBody: {
          required: true,
          content: { 'application/json': { schema: { $ref: '#/components/schemas/UpdateCourseRequest' } } },
        },
        responses: {
          '200': {
            description: 'Curso atualizado',
            content: {
              'application/json': {
                schema: { type: 'object', properties: { data: { $ref: '#/components/schemas/Course' } } },
              },
            },
          },
          '404': {
            description: 'Curso não encontrado',
            content: { 'application/json': { schema: { $ref: '#/components/schemas/Error' } } },
          },
        },
      },
      delete: {
        tags: ['Courses'],
        summary: 'Arquivar curso (soft delete)',
        security: [{ bearerAuth: [] }],
        parameters: [{ name: 'id', in: 'path', required: true, schema: { type: 'string', format: 'uuid' } }],
        responses: {
          '204': { description: 'Curso arquivado' },
          '404': {
            description: 'Curso não encontrado',
            content: { 'application/json': { schema: { $ref: '#/components/schemas/Error' } } },
          },
        },
      },
    },
    '/disciplines': {
      get: {
        tags: ['Disciplines'],
        summary: 'Listar disciplinas do professor',
        security: [{ bearerAuth: [] }],
        responses: {
          '200': {
            description: 'Lista de disciplinas',
            content: {
              'application/json': {
                schema: {
                  type: 'object',
                  properties: {
                    data: { type: 'array', items: { $ref: '#/components/schemas/Discipline' } },
                  },
                },
              },
            },
          },
        },
      },
      post: {
        tags: ['Disciplines'],
        summary: 'Criar disciplina',
        security: [{ bearerAuth: [] }],
        requestBody: {
          required: true,
          content: {
            'application/json': { schema: { $ref: '#/components/schemas/CreateDisciplineRequest' } },
          },
        },
        responses: {
          '201': {
            description: 'Disciplina criada',
            content: {
              'application/json': {
                schema: {
                  type: 'object',
                  properties: { data: { $ref: '#/components/schemas/Discipline' } },
                },
              },
            },
          },
          '409': {
            description: 'Já existe uma disciplina com este nome para o professor',
            content: { 'application/json': { schema: { $ref: '#/components/schemas/Error' } } },
          },
        },
      },
    },
    '/disciplines/{id}': {
      patch: {
        tags: ['Disciplines'],
        summary: 'Atualizar disciplina',
        security: [{ bearerAuth: [] }],
        parameters: [{ name: 'id', in: 'path', required: true, schema: { type: 'string', format: 'uuid' } }],
        requestBody: {
          required: true,
          content: {
            'application/json': { schema: { $ref: '#/components/schemas/UpdateDisciplineRequest' } },
          },
        },
        responses: {
          '200': {
            description: 'Disciplina atualizada',
            content: {
              'application/json': {
                schema: {
                  type: 'object',
                  properties: { data: { $ref: '#/components/schemas/Discipline' } },
                },
              },
            },
          },
          '404': {
            description: 'Disciplina não encontrada',
            content: { 'application/json': { schema: { $ref: '#/components/schemas/Error' } } },
          },
        },
      },
      delete: {
        tags: ['Disciplines'],
        summary: 'Arquivar disciplina (soft delete)',
        security: [{ bearerAuth: [] }],
        parameters: [{ name: 'id', in: 'path', required: true, schema: { type: 'string', format: 'uuid' } }],
        responses: {
          '204': { description: 'Disciplina arquivada' },
          '404': {
            description: 'Disciplina não encontrada',
            content: { 'application/json': { schema: { $ref: '#/components/schemas/Error' } } },
          },
        },
      },
    },
    '/courses/{courseId}/disciplines': {
      get: {
        tags: ['Courses'],
        summary: 'Listar disciplinas vinculadas ao curso',
        security: [{ bearerAuth: [] }],
        parameters: [
          { name: 'courseId', in: 'path', required: true, schema: { type: 'string', format: 'uuid' } },
        ],
        responses: {
          '200': {
            description: 'Vínculos curso-disciplina',
            content: {
              'application/json': {
                schema: {
                  type: 'object',
                  properties: {
                    data: { type: 'array', items: { $ref: '#/components/schemas/CourseDiscipline' } },
                  },
                },
              },
            },
          },
          '404': {
            description: 'Curso não encontrado',
            content: { 'application/json': { schema: { $ref: '#/components/schemas/Error' } } },
          },
        },
      },
      post: {
        tags: ['Courses'],
        summary: 'Vincular disciplina ao curso',
        security: [{ bearerAuth: [] }],
        parameters: [
          { name: 'courseId', in: 'path', required: true, schema: { type: 'string', format: 'uuid' } },
        ],
        requestBody: {
          required: true,
          content: {
            'application/json': {
              schema: { $ref: '#/components/schemas/LinkDisciplineToCourseRequest' },
            },
          },
        },
        responses: {
          '201': {
            description: 'Disciplina vinculada',
            content: {
              'application/json': {
                schema: {
                  type: 'object',
                  properties: { data: { $ref: '#/components/schemas/CourseDiscipline' } },
                },
              },
            },
          },
          '404': {
            description: 'Curso ou disciplina não encontrados',
            content: { 'application/json': { schema: { $ref: '#/components/schemas/Error' } } },
          },
          '409': {
            description: 'Disciplina já vinculada a este curso',
            content: { 'application/json': { schema: { $ref: '#/components/schemas/Error' } } },
          },
        },
      },
    },
    '/courses/{courseId}/disciplines/{disciplineId}': {
      delete: {
        tags: ['Courses'],
        summary: 'Desvincular disciplina do curso',
        security: [{ bearerAuth: [] }],
        parameters: [
          { name: 'courseId', in: 'path', required: true, schema: { type: 'string', format: 'uuid' } },
          { name: 'disciplineId', in: 'path', required: true, schema: { type: 'string', format: 'uuid' } },
        ],
        responses: {
          '204': { description: 'Vínculo removido' },
          '404': {
            description: 'Vínculo não encontrado',
            content: { 'application/json': { schema: { $ref: '#/components/schemas/Error' } } },
          },
        },
      },
    },
    '/assessment-periods': {
      get: {
        tags: ['Assessment Periods'],
        summary: 'Listar períodos avaliativos de um ano letivo',
        security: [{ bearerAuth: [] }],
        parameters: [
          {
            name: 'academicYearId',
            in: 'query',
            required: true,
            schema: { type: 'string', format: 'uuid' },
          },
        ],
        responses: {
          '200': {
            description: 'Lista ordenada por sortOrder',
            content: {
              'application/json': {
                schema: {
                  type: 'object',
                  properties: {
                    data: { type: 'array', items: { $ref: '#/components/schemas/AssessmentPeriod' } },
                  },
                },
              },
            },
          },
          '404': {
            description: 'Ano letivo não encontrado',
            content: { 'application/json': { schema: { $ref: '#/components/schemas/Error' } } },
          },
        },
      },
      post: {
        tags: ['Assessment Periods'],
        summary: 'Criar período avaliativo',
        security: [{ bearerAuth: [] }],
        requestBody: {
          required: true,
          content: {
            'application/json': {
              schema: { $ref: '#/components/schemas/CreateAssessmentPeriodRequest' },
            },
          },
        },
        responses: {
          '201': {
            description: 'Período avaliativo criado',
            content: {
              'application/json': {
                schema: {
                  type: 'object',
                  properties: { data: { $ref: '#/components/schemas/AssessmentPeriod' } },
                },
              },
            },
          },
          '404': {
            description: 'Ano letivo não encontrado',
            content: { 'application/json': { schema: { $ref: '#/components/schemas/Error' } } },
          },
        },
      },
    },
    '/assessment-periods/{id}': {
      patch: {
        tags: ['Assessment Periods'],
        summary: 'Atualizar período avaliativo',
        security: [{ bearerAuth: [] }],
        parameters: [{ name: 'id', in: 'path', required: true, schema: { type: 'string', format: 'uuid' } }],
        requestBody: {
          required: true,
          content: {
            'application/json': {
              schema: { $ref: '#/components/schemas/UpdateAssessmentPeriodRequest' },
            },
          },
        },
        responses: {
          '200': {
            description: 'Período avaliativo atualizado',
            content: {
              'application/json': {
                schema: {
                  type: 'object',
                  properties: { data: { $ref: '#/components/schemas/AssessmentPeriod' } },
                },
              },
            },
          },
          '404': {
            description: 'Período avaliativo não encontrado',
            content: { 'application/json': { schema: { $ref: '#/components/schemas/Error' } } },
          },
        },
      },
    },
    '/assessment-periods/reorder': {
      put: {
        tags: ['Assessment Periods'],
        summary: 'Reordenar períodos avaliativos de um ano letivo',
        security: [{ bearerAuth: [] }],
        requestBody: {
          required: true,
          content: {
            'application/json': {
              schema: { $ref: '#/components/schemas/ReorderAssessmentPeriodsRequest' },
            },
          },
        },
        responses: {
          '200': {
            description: 'Nova ordem aplicada',
            content: {
              'application/json': {
                schema: {
                  type: 'object',
                  properties: {
                    data: { type: 'array', items: { $ref: '#/components/schemas/AssessmentPeriod' } },
                  },
                },
              },
            },
          },
          '404': {
            description: 'Ano letivo não encontrado',
            content: { 'application/json': { schema: { $ref: '#/components/schemas/Error' } } },
          },
          '422': {
            description: 'orderedIds não corresponde exatamente aos períodos do ano letivo',
            content: { 'application/json': { schema: { $ref: '#/components/schemas/Error' } } },
          },
        },
      },
    },
    '/students': {
      get: {
        tags: ['Students'],
        summary: 'Listar alunos do professor',
        security: [{ bearerAuth: [] }],
        parameters: [{ name: 'search', in: 'query', schema: { type: 'string' } }],
        responses: {
          '200': {
            description: 'Lista de alunos',
            content: {
              'application/json': {
                schema: {
                  type: 'object',
                  properties: { data: { type: 'array', items: { $ref: '#/components/schemas/Student' } } },
                },
              },
            },
          },
        },
      },
      post: {
        tags: ['Students'],
        summary: 'Criar aluno',
        security: [{ bearerAuth: [] }],
        requestBody: {
          required: true,
          content: { 'application/json': { schema: { $ref: '#/components/schemas/CreateStudentRequest' } } },
        },
        responses: {
          '201': {
            description: 'Aluno criado',
            content: {
              'application/json': {
                schema: { type: 'object', properties: { data: { $ref: '#/components/schemas/Student' } } },
              },
            },
          },
        },
      },
    },
    '/students/{id}': {
      get: {
        tags: ['Students'],
        summary: 'Obter aluno',
        security: [{ bearerAuth: [] }],
        parameters: [{ name: 'id', in: 'path', required: true, schema: { type: 'string', format: 'uuid' } }],
        responses: {
          '200': {
            description: 'Aluno',
            content: {
              'application/json': {
                schema: { type: 'object', properties: { data: { $ref: '#/components/schemas/Student' } } },
              },
            },
          },
          '404': {
            description: 'Aluno não encontrado',
            content: { 'application/json': { schema: { $ref: '#/components/schemas/Error' } } },
          },
        },
      },
      patch: {
        tags: ['Students'],
        summary: 'Atualizar aluno',
        security: [{ bearerAuth: [] }],
        parameters: [{ name: 'id', in: 'path', required: true, schema: { type: 'string', format: 'uuid' } }],
        requestBody: {
          required: true,
          content: { 'application/json': { schema: { $ref: '#/components/schemas/UpdateStudentRequest' } } },
        },
        responses: {
          '200': {
            description: 'Aluno atualizado',
            content: {
              'application/json': {
                schema: { type: 'object', properties: { data: { $ref: '#/components/schemas/Student' } } },
              },
            },
          },
          '404': {
            description: 'Aluno não encontrado',
            content: { 'application/json': { schema: { $ref: '#/components/schemas/Error' } } },
          },
        },
      },
      delete: {
        tags: ['Students'],
        summary: 'Arquivar aluno (soft delete)',
        security: [{ bearerAuth: [] }],
        parameters: [{ name: 'id', in: 'path', required: true, schema: { type: 'string', format: 'uuid' } }],
        responses: {
          '204': { description: 'Aluno arquivado' },
          '404': {
            description: 'Aluno não encontrado',
            content: { 'application/json': { schema: { $ref: '#/components/schemas/Error' } } },
          },
        },
      },
    },
    '/classes': {
      get: {
        tags: ['Classes'],
        summary: 'Listar turmas do professor',
        security: [{ bearerAuth: [] }],
        parameters: [
          { name: 'academicYearId', in: 'query', schema: { type: 'string', format: 'uuid' } },
          { name: 'courseId', in: 'query', schema: { type: 'string', format: 'uuid' } },
          { name: 'disciplineId', in: 'query', schema: { type: 'string', format: 'uuid' } },
          { name: 'status', in: 'query', schema: { type: 'string', enum: ['ACTIVE', 'ARCHIVED'] } },
        ],
        responses: {
          '200': {
            description: 'Lista de turmas',
            content: {
              'application/json': {
                schema: {
                  type: 'object',
                  properties: { data: { type: 'array', items: { $ref: '#/components/schemas/Class' } } },
                },
              },
            },
          },
        },
      },
      post: {
        tags: ['Classes'],
        summary: 'Criar turma',
        description:
          'Cada `disciplineId` deve estar na grade do curso (`CourseDiscipline` ativo).',
        security: [{ bearerAuth: [] }],
        requestBody: {
          required: true,
          content: { 'application/json': { schema: { $ref: '#/components/schemas/CreateClassRequest' } } },
        },
        responses: {
          '201': {
            description: 'Turma criada',
            content: {
              'application/json': {
                schema: { type: 'object', properties: { data: { $ref: '#/components/schemas/Class' } } },
              },
            },
          },
          '400': {
            description: 'Alguma disciplina não pertence à grade do curso',
            content: { 'application/json': { schema: { $ref: '#/components/schemas/Error' } } },
          },
          '404': {
            description: 'Ano letivo, curso ou alguma disciplina não encontrados',
            content: { 'application/json': { schema: { $ref: '#/components/schemas/Error' } } },
          },
          '409': {
            description: 'Turma já existe para este ano letivo e curso',
            content: { 'application/json': { schema: { $ref: '#/components/schemas/Error' } } },
          },
          '422': { description: 'disciplineIds vazio (ao menos uma disciplina é obrigatória)' },
        },
      },
    },
    '/classes/{id}': {
      get: {
        tags: ['Classes'],
        summary: 'Obter turma',
        security: [{ bearerAuth: [] }],
        parameters: [{ name: 'id', in: 'path', required: true, schema: { type: 'string', format: 'uuid' } }],
        responses: {
          '200': {
            description: 'Turma',
            content: {
              'application/json': {
                schema: { type: 'object', properties: { data: { $ref: '#/components/schemas/Class' } } },
              },
            },
          },
          '404': {
            description: 'Turma não encontrada',
            content: { 'application/json': { schema: { $ref: '#/components/schemas/Error' } } },
          },
        },
      },
      patch: {
        tags: ['Classes'],
        summary: 'Atualizar turma',
        security: [{ bearerAuth: [] }],
        parameters: [{ name: 'id', in: 'path', required: true, schema: { type: 'string', format: 'uuid' } }],
        requestBody: {
          required: true,
          content: { 'application/json': { schema: { $ref: '#/components/schemas/UpdateClassRequest' } } },
        },
        responses: {
          '200': {
            description: 'Turma atualizada',
            content: {
              'application/json': {
                schema: { type: 'object', properties: { data: { $ref: '#/components/schemas/Class' } } },
              },
            },
          },
          '404': {
            description: 'Turma não encontrada',
            content: { 'application/json': { schema: { $ref: '#/components/schemas/Error' } } },
          },
        },
      },
    },
    '/classes/{id}/archive': {
      post: {
        tags: ['Classes'],
        summary: 'Arquivar turma (status ARCHIVED)',
        security: [{ bearerAuth: [] }],
        parameters: [{ name: 'id', in: 'path', required: true, schema: { type: 'string', format: 'uuid' } }],
        responses: {
          '200': {
            description: 'Turma arquivada',
            content: {
              'application/json': {
                schema: { type: 'object', properties: { data: { $ref: '#/components/schemas/Class' } } },
              },
            },
          },
          '404': {
            description: 'Turma não encontrada',
            content: { 'application/json': { schema: { $ref: '#/components/schemas/Error' } } },
          },
        },
      },
    },
    '/classes/{classId}/enrollments': {
      get: {
        tags: ['Classes'],
        summary: 'Listar alunos matriculados na turma',
        security: [{ bearerAuth: [] }],
        parameters: [
          { name: 'classId', in: 'path', required: true, schema: { type: 'string', format: 'uuid' } },
        ],
        responses: {
          '200': {
            description: 'Matrículas ativas da turma',
            content: {
              'application/json': {
                schema: {
                  type: 'object',
                  properties: {
                    data: { type: 'array', items: { $ref: '#/components/schemas/Enrollment' } },
                  },
                },
              },
            },
          },
          '404': {
            description: 'Turma não encontrada',
            content: { 'application/json': { schema: { $ref: '#/components/schemas/Error' } } },
          },
        },
      },
      post: {
        tags: ['Classes'],
        summary: 'Matricular aluno na turma',
        security: [{ bearerAuth: [] }],
        parameters: [
          { name: 'classId', in: 'path', required: true, schema: { type: 'string', format: 'uuid' } },
        ],
        requestBody: {
          required: true,
          content: { 'application/json': { schema: { $ref: '#/components/schemas/EnrollStudentRequest' } } },
        },
        responses: {
          '201': {
            description: 'Matrícula criada',
            content: {
              'application/json': {
                schema: {
                  type: 'object',
                  properties: { data: { $ref: '#/components/schemas/Enrollment' } },
                },
              },
            },
          },
          '404': {
            description: 'Turma ou aluno não encontrados',
            content: { 'application/json': { schema: { $ref: '#/components/schemas/Error' } } },
          },
          '409': {
            description: 'Aluno já matriculado nesta turma',
            content: { 'application/json': { schema: { $ref: '#/components/schemas/Error' } } },
          },
        },
      },
    },
    '/classes/{classId}/enrollments/bulk': {
      post: {
        tags: ['Classes'],
        summary: 'Matricular vários alunos na turma',
        description:
          'Matricula um lote de alunos. Já matriculados ou inexistentes entram em `skipped` sem abortar o lote.',
        security: [{ bearerAuth: [] }],
        parameters: [
          { name: 'classId', in: 'path', required: true, schema: { type: 'string', format: 'uuid' } },
        ],
        requestBody: {
          required: true,
          content: {
            'application/json': { schema: { $ref: '#/components/schemas/BulkEnrollStudentsRequest' } },
          },
        },
        responses: {
          '201': {
            description: 'Lote processado com ao menos uma matrícula criada',
            content: {
              'application/json': {
                schema: {
                  type: 'object',
                  properties: { data: { $ref: '#/components/schemas/BulkEnrollStudentsResponse' } },
                },
              },
            },
          },
          '400': {
            description: 'Nenhum aluno pôde ser matriculado ou lista inválida',
            content: { 'application/json': { schema: { $ref: '#/components/schemas/Error' } } },
          },
          '404': {
            description: 'Turma não encontrada',
            content: { 'application/json': { schema: { $ref: '#/components/schemas/Error' } } },
          },
        },
      },
    },
    '/classes/{classId}/disciplines': {
      get: {
        tags: ['Classes'],
        summary: 'Listar disciplinas vinculadas à turma',
        security: [{ bearerAuth: [] }],
        parameters: [
          { name: 'classId', in: 'path', required: true, schema: { type: 'string', format: 'uuid' } },
        ],
        responses: {
          '200': {
            description: 'Vínculos turma-disciplina',
            content: {
              'application/json': {
                schema: {
                  type: 'object',
                  properties: {
                    data: { type: 'array', items: { $ref: '#/components/schemas/ClassDiscipline' } },
                  },
                },
              },
            },
          },
          '404': {
            description: 'Turma não encontrada',
            content: { 'application/json': { schema: { $ref: '#/components/schemas/Error' } } },
          },
        },
      },
      post: {
        tags: ['Classes'],
        summary: 'Vincular disciplina adicional à turma',
        description:
          'A disciplina deve estar na grade do curso da turma (`CourseDiscipline` ativo).',
        security: [{ bearerAuth: [] }],
        parameters: [
          { name: 'classId', in: 'path', required: true, schema: { type: 'string', format: 'uuid' } },
        ],
        requestBody: {
          required: true,
          content: {
            'application/json': { schema: { $ref: '#/components/schemas/LinkDisciplineToClassRequest' } },
          },
        },
        responses: {
          '201': {
            description: 'Disciplina vinculada',
            content: {
              'application/json': {
                schema: {
                  type: 'object',
                  properties: { data: { $ref: '#/components/schemas/ClassDiscipline' } },
                },
              },
            },
          },
          '400': {
            description: 'Disciplina não pertence à grade do curso da turma',
            content: { 'application/json': { schema: { $ref: '#/components/schemas/Error' } } },
          },
          '404': {
            description: 'Turma ou disciplina não encontrados',
            content: { 'application/json': { schema: { $ref: '#/components/schemas/Error' } } },
          },
          '409': {
            description: 'Disciplina já vinculada a esta turma',
            content: { 'application/json': { schema: { $ref: '#/components/schemas/Error' } } },
          },
        },
      },
    },
    '/classes/{classId}/disciplines/{disciplineId}': {
      delete: {
        tags: ['Classes'],
        summary: 'Desvincular disciplina da turma (soft delete do vínculo)',
        security: [{ bearerAuth: [] }],
        parameters: [
          { name: 'classId', in: 'path', required: true, schema: { type: 'string', format: 'uuid' } },
          { name: 'disciplineId', in: 'path', required: true, schema: { type: 'string', format: 'uuid' } },
        ],
        responses: {
          '204': { description: 'Vínculo removido' },
          '404': {
            description: 'Vínculo não encontrado',
            content: { 'application/json': { schema: { $ref: '#/components/schemas/Error' } } },
          },
        },
      },
    },
    '/classes/{classId}/enrollments/{studentId}': {
      delete: {
        tags: ['Classes'],
        summary: 'Encerrar matrícula do aluno na turma (status WITHDRAWN)',
        security: [{ bearerAuth: [] }],
        parameters: [
          { name: 'classId', in: 'path', required: true, schema: { type: 'string', format: 'uuid' } },
          { name: 'studentId', in: 'path', required: true, schema: { type: 'string', format: 'uuid' } },
        ],
        responses: {
          '204': { description: 'Matrícula encerrada' },
          '404': {
            description: 'Matrícula ativa não encontrada',
            content: { 'application/json': { schema: { $ref: '#/components/schemas/Error' } } },
          },
        },
      },
    },
    '/classes/{classId}/lessons': {
      get: {
        tags: ['Lessons'],
        summary: 'Listar aulas da turma',
        security: [{ bearerAuth: [] }],
        parameters: [
          { name: 'classId', in: 'path', required: true, schema: { type: 'string', format: 'uuid' } },
          { name: 'disciplineId', in: 'query', schema: { type: 'string', format: 'uuid' } },
        ],
        responses: {
          '200': {
            description: 'Lista de aulas',
            content: {
              'application/json': {
                schema: {
                  type: 'object',
                  properties: { data: { type: 'array', items: { $ref: '#/components/schemas/Lesson' } } },
                },
              },
            },
          },
        },
      },
      post: {
        tags: ['Lessons'],
        summary: 'Criar aula (valida endTime > startTime)',
        security: [{ bearerAuth: [] }],
        parameters: [
          { name: 'classId', in: 'path', required: true, schema: { type: 'string', format: 'uuid' } },
        ],
        requestBody: {
          required: true,
          content: { 'application/json': { schema: { $ref: '#/components/schemas/CreateLessonRequest' } } },
        },
        responses: {
          '201': {
            description: 'Aula criada',
            content: {
              'application/json': {
                schema: { type: 'object', properties: { data: { $ref: '#/components/schemas/Lesson' } } },
              },
            },
          },
          '422': { description: 'Validação (ex.: endTime <= startTime)' },
        },
      },
    },
    '/lessons/{id}': {
      get: {
        tags: ['Lessons'],
        summary: 'Obter aula',
        security: [{ bearerAuth: [] }],
        parameters: [{ name: 'id', in: 'path', required: true, schema: { type: 'string', format: 'uuid' } }],
        responses: { '200': { description: 'Aula' }, '404': { description: 'Não encontrada' } },
      },
      patch: {
        tags: ['Lessons'],
        summary: 'Atualizar aula',
        security: [{ bearerAuth: [] }],
        parameters: [{ name: 'id', in: 'path', required: true, schema: { type: 'string', format: 'uuid' } }],
        requestBody: {
          content: { 'application/json': { schema: { $ref: '#/components/schemas/UpdateLessonRequest' } } },
        },
        responses: { '200': { description: 'Aula atualizada' }, '404': { description: 'Não encontrada' } },
      },
      delete: {
        tags: ['Lessons'],
        summary: 'Excluir aula (soft delete)',
        security: [{ bearerAuth: [] }],
        parameters: [{ name: 'id', in: 'path', required: true, schema: { type: 'string', format: 'uuid' } }],
        responses: { '204': { description: 'Removida' }, '404': { description: 'Não encontrada' } },
      },
    },
    '/classes/{classId}/contents': {
      get: {
        tags: ['Contents'],
        summary: 'Listar conteúdos da turma',
        security: [{ bearerAuth: [] }],
        parameters: [
          { name: 'classId', in: 'path', required: true, schema: { type: 'string', format: 'uuid' } },
          {
            name: 'status',
            in: 'query',
            schema: { type: 'string', enum: ['IN_PROGRESS', 'COMPLETED'] },
          },
          { name: 'disciplineId', in: 'query', schema: { type: 'string', format: 'uuid' } },
        ],
        responses: {
          '200': {
            description: 'Lista de conteúdos',
            content: {
              'application/json': {
                schema: {
                  type: 'object',
                  properties: { data: { type: 'array', items: { $ref: '#/components/schemas/Content' } } },
                },
              },
            },
          },
        },
      },
      post: {
        tags: ['Contents'],
        summary: 'Criar conteúdo (status inicial IN_PROGRESS)',
        security: [{ bearerAuth: [] }],
        parameters: [
          { name: 'classId', in: 'path', required: true, schema: { type: 'string', format: 'uuid' } },
        ],
        requestBody: {
          required: true,
          content: { 'application/json': { schema: { $ref: '#/components/schemas/CreateContentRequest' } } },
        },
        responses: { '201': { description: 'Conteúdo criado' } },
      },
    },
    '/contents/{id}': {
      patch: {
        tags: ['Contents'],
        summary: 'Atualizar conteúdo',
        security: [{ bearerAuth: [] }],
        parameters: [{ name: 'id', in: 'path', required: true, schema: { type: 'string', format: 'uuid' } }],
        requestBody: {
          content: { 'application/json': { schema: { $ref: '#/components/schemas/UpdateContentRequest' } } },
        },
        responses: { '200': { description: 'Conteúdo atualizado' }, '404': { description: 'Não encontrado' } },
      },
    },
    '/contents/{id}/complete': {
      post: {
        tags: ['Contents'],
        summary: 'Concluir conteúdo (status=COMPLETED, completedAt=now)',
        security: [{ bearerAuth: [] }],
        parameters: [{ name: 'id', in: 'path', required: true, schema: { type: 'string', format: 'uuid' } }],
        responses: { '200': { description: 'Conteúdo concluído' }, '422': { description: 'Já concluído' } },
      },
    },
    '/contents/{id}/reopen': {
      post: {
        tags: ['Contents'],
        summary: 'Reabrir conteúdo (status=IN_PROGRESS, completedAt=null)',
        security: [{ bearerAuth: [] }],
        parameters: [{ name: 'id', in: 'path', required: true, schema: { type: 'string', format: 'uuid' } }],
        responses: { '200': { description: 'Conteúdo reaberto' }, '422': { description: 'Já em andamento' } },
      },
    },
    '/lessons/{lessonId}/contents': {
      post: {
        tags: ['Contents'],
        summary: 'Vincular conteúdo a uma aula (mesma turma)',
        security: [{ bearerAuth: [] }],
        parameters: [
          { name: 'lessonId', in: 'path', required: true, schema: { type: 'string', format: 'uuid' } },
        ],
        requestBody: {
          required: true,
          content: {
            'application/json': { schema: { $ref: '#/components/schemas/LinkContentToLessonRequest' } },
          },
        },
        responses: {
          '201': { description: 'Vínculo criado' },
          '409': { description: 'Conteúdo já vinculado à aula' },
          '422': { description: 'Conteúdo não pertence à turma da aula' },
        },
      },
    },
    '/lessons/{lessonId}/contents/{contentId}': {
      delete: {
        tags: ['Contents'],
        summary: 'Desvincular conteúdo de uma aula',
        security: [{ bearerAuth: [] }],
        parameters: [
          { name: 'lessonId', in: 'path', required: true, schema: { type: 'string', format: 'uuid' } },
          { name: 'contentId', in: 'path', required: true, schema: { type: 'string', format: 'uuid' } },
        ],
        responses: { '204': { description: 'Vínculo removido' }, '404': { description: 'Não encontrado' } },
      },
    },
    '/lessons/{lessonId}/attendance': {
      get: {
        tags: ['Attendance'],
        summary: 'Obter chamada da aula (matrículas ativas + status atual)',
        security: [{ bearerAuth: [] }],
        parameters: [
          {
            name: 'lessonId',
            in: 'path',
            required: true,
            schema: { type: 'string', format: 'uuid' },
          },
        ],
        responses: {
          '200': {
            description: 'Folha de chamada',
            content: {
              'application/json': {
                schema: {
                  type: 'object',
                  properties: { data: { $ref: '#/components/schemas/AttendanceSheet' } },
                },
              },
            },
          },
          '404': { description: 'Aula não encontrada' },
        },
      },
      put: {
        tags: ['Attendance'],
        summary: 'Salvar chamada em lote (upsert por aluno)',
        security: [{ bearerAuth: [] }],
        parameters: [
          {
            name: 'lessonId',
            in: 'path',
            required: true,
            schema: { type: 'string', format: 'uuid' },
          },
        ],
        requestBody: {
          required: true,
          content: { 'application/json': { schema: { $ref: '#/components/schemas/SaveAttendanceRequest' } } },
        },
        responses: {
          '200': { description: 'Chamada salva' },
          '422': { description: 'Aluno sem matrícula ativa na turma' },
        },
      },
    },
    '/lessons/{lessonId}/attendance/complete': {
      post: {
        tags: ['Attendance'],
        summary: 'Concluir chamada (exige todos os alunos ativos já registrados)',
        security: [{ bearerAuth: [] }],
        parameters: [
          {
            name: 'lessonId',
            in: 'path',
            required: true,
            schema: { type: 'string', format: 'uuid' },
          },
        ],
        responses: {
          '200': { description: 'Chamada concluída (lesson.attendanceCompleted=true)' },
          '422': { description: 'Existem alunos ativos sem registro de chamada' },
        },
      },
    },
    '/classes/{classId}/activities': {
      get: {
        tags: ['Activities'],
        summary: 'Listar atividades da turma',
        security: [{ bearerAuth: [] }],
        parameters: [
          { name: 'classId', in: 'path', required: true, schema: { type: 'string', format: 'uuid' } },
          { name: 'disciplineId', in: 'query', schema: { type: 'string', format: 'uuid' } },
        ],
        responses: {
          '200': {
            description: 'Lista de atividades',
            content: {
              'application/json': {
                schema: {
                  type: 'object',
                  properties: { data: { type: 'array', items: { $ref: '#/components/schemas/Activity' } } },
                },
              },
            },
          },
        },
      },
      post: {
        tags: ['Activities'],
        summary: 'Criar atividade e gerar submissions PENDING para alunos ativos',
        security: [{ bearerAuth: [] }],
        parameters: [
          { name: 'classId', in: 'path', required: true, schema: { type: 'string', format: 'uuid' } },
        ],
        requestBody: {
          required: true,
          content: { 'application/json': { schema: { $ref: '#/components/schemas/CreateActivityRequest' } } },
        },
        responses: {
          '201': { description: 'Atividade criada' },
          '422': { description: 'originLessonId não pertence à turma' },
        },
      },
    },
    '/activities/{id}': {
      get: {
        tags: ['Activities'],
        summary: 'Obter atividade com resumo de submissions',
        security: [{ bearerAuth: [] }],
        parameters: [{ name: 'id', in: 'path', required: true, schema: { type: 'string', format: 'uuid' } }],
        responses: {
          '200': {
            description: 'Atividade + submissions + resumo',
            content: {
              'application/json': {
                schema: {
                  type: 'object',
                  properties: { data: { $ref: '#/components/schemas/GetActivityResponse' } },
                },
              },
            },
          },
          '404': { description: 'Não encontrada' },
        },
      },
      patch: {
        tags: ['Activities'],
        summary: 'Atualizar atividade',
        security: [{ bearerAuth: [] }],
        parameters: [{ name: 'id', in: 'path', required: true, schema: { type: 'string', format: 'uuid' } }],
        requestBody: {
          content: { 'application/json': { schema: { $ref: '#/components/schemas/UpdateActivityRequest' } } },
        },
        responses: { '200': { description: 'Atividade atualizada' }, '404': { description: 'Não encontrada' } },
      },
    },
    '/activities/{id}/groups': {
      post: {
        tags: ['Activities'],
        summary: 'Criar/substituir grupos da atividade (mode=GROUP) e atribuir groupId às submissions',
        security: [{ bearerAuth: [] }],
        parameters: [{ name: 'id', in: 'path', required: true, schema: { type: 'string', format: 'uuid' } }],
        requestBody: {
          required: true,
          content: {
            'application/json': { schema: { $ref: '#/components/schemas/CreateActivityGroupsRequest' } },
          },
        },
        responses: {
          '201': {
            description: 'Grupos criados',
            content: {
              'application/json': {
                schema: {
                  type: 'object',
                  properties: {
                    data: { type: 'array', items: { $ref: '#/components/schemas/ActivityGroup' } },
                  },
                },
              },
            },
          },
          '422': { description: 'Atividade não é GROUP ou aluno duplicado/sem matrícula ativa' },
        },
      },
    },
    '/activities/{id}/submissions': {
      get: {
        tags: ['Activities'],
        summary: 'Listar submissions da atividade',
        security: [{ bearerAuth: [] }],
        parameters: [{ name: 'id', in: 'path', required: true, schema: { type: 'string', format: 'uuid' } }],
        responses: {
          '200': {
            description: 'Lista de submissions',
            content: {
              'application/json': {
                schema: {
                  type: 'object',
                  properties: { data: { type: 'array', items: { $ref: '#/components/schemas/Submission' } } },
                },
              },
            },
          },
        },
      },
    },
    '/submissions/{id}': {
      patch: {
        tags: ['Submissions'],
        summary: 'Marcar submission como SUBMITTED',
        security: [{ bearerAuth: [] }],
        parameters: [{ name: 'id', in: 'path', required: true, schema: { type: 'string', format: 'uuid' } }],
        requestBody: {
          required: true,
          content: { 'application/json': { schema: { $ref: '#/components/schemas/UpdateSubmissionRequest' } } },
        },
        responses: {
          '200': { description: 'Submission atualizada' },
          '422': { description: 'Submission já avaliada (GRADED)' },
        },
      },
    },
    '/submissions/{id}/grade': {
      post: {
        tags: ['Submissions'],
        summary: 'Avaliar submission individual (0..maxScore)',
        security: [{ bearerAuth: [] }],
        parameters: [{ name: 'id', in: 'path', required: true, schema: { type: 'string', format: 'uuid' } }],
        requestBody: {
          required: true,
          content: { 'application/json': { schema: { $ref: '#/components/schemas/GradeSubmissionRequest' } } },
        },
        responses: {
          '200': { description: 'Submission avaliada (status=GRADED)' },
          '422': { description: 'score fora do intervalo permitido' },
        },
      },
    },
    '/activities/{activityId}/groups/{groupId}/grade-shared': {
      post: {
        tags: ['Submissions'],
        summary: 'Avaliar grupo (gradeMode=SHARED): aplica a mesma nota a todos os membros',
        security: [{ bearerAuth: [] }],
        parameters: [
          { name: 'activityId', in: 'path', required: true, schema: { type: 'string', format: 'uuid' } },
          { name: 'groupId', in: 'path', required: true, schema: { type: 'string', format: 'uuid' } },
        ],
        requestBody: {
          required: true,
          content: { 'application/json': { schema: { $ref: '#/components/schemas/GradeSubmissionRequest' } } },
        },
        responses: {
          '200': {
            description: 'Submissions do grupo avaliadas',
            content: {
              'application/json': {
                schema: {
                  type: 'object',
                  properties: { data: { type: 'array', items: { $ref: '#/components/schemas/Submission' } } },
                },
              },
            },
          },
          '422': { description: 'Atividade não é gradeMode=SHARED ou score fora do intervalo' },
        },
      },
    },
    '/dashboard': {
      get: {
        tags: ['Dashboard'],
        summary: 'Dashboard com AttentionItems e resumo (Insights Engine)',
        security: [{ bearerAuth: [] }],
        parameters: [
          { name: 'academicYearId', in: 'query', schema: { type: 'string', format: 'uuid' } },
          { name: 'classId', in: 'query', schema: { type: 'string', format: 'uuid' } },
        ],
        responses: {
          '200': {
            description: 'AttentionItems ordenados por severidade + contagem, com resumo',
            content: {
              'application/json': {
                schema: {
                  type: 'object',
                  properties: { data: { $ref: '#/components/schemas/DashboardResponse' } },
                },
              },
            },
          },
        },
      },
    },
    '/attention-items': {
      get: {
        tags: ['Dashboard'],
        summary: 'Lista unificada de AttentionItems (Insights Engine)',
        security: [{ bearerAuth: [] }],
        parameters: [
          { name: 'academicYearId', in: 'query', schema: { type: 'string', format: 'uuid' } },
          { name: 'classId', in: 'query', schema: { type: 'string', format: 'uuid' } },
        ],
        responses: {
          '200': {
            description: 'AttentionItems ordenados por severidade + contagem',
            content: {
              'application/json': {
                schema: {
                  type: 'object',
                  properties: { data: { $ref: '#/components/schemas/AttentionItemsResponse' } },
                },
              },
            },
          },
        },
      },
    },
    '/reports/{reportType}': {
      get: {
        tags: ['Reports'],
        summary: 'Executar relatório filtrável',
        security: [{ bearerAuth: [] }],
        parameters: [
          {
            name: 'reportType',
            in: 'path',
            required: true,
            schema: {
              type: 'string',
              enum: [
                'excess-absences',
                'pending-activities',
                'ungraded-activities',
                'contents-in-progress',
                'lessons-without-attendance',
                'absence-vs-non-submission',
                'attendance-percentage',
                'class-average',
                'grades-by-student',
                'attendance-by-student',
                'submission-status',
                'lessons-taught',
                'students-without-grade',
                'average-by-activity',
              ],
            },
          },
          { name: 'academicYearId', in: 'query', schema: { type: 'string', format: 'uuid' } },
          { name: 'courseId', in: 'query', schema: { type: 'string', format: 'uuid' } },
          { name: 'disciplineId', in: 'query', schema: { type: 'string', format: 'uuid' } },
          { name: 'classId', in: 'query', schema: { type: 'string', format: 'uuid' } },
          { name: 'assessmentPeriodId', in: 'query', schema: { type: 'string', format: 'uuid' } },
          { name: 'from', in: 'query', schema: { type: 'string', format: 'date' } },
          { name: 'to', in: 'query', schema: { type: 'string', format: 'date' } },
          {
            name: 'threshold',
            in: 'query',
            description: 'Usado apenas por excess-absences (default 5)',
            schema: { type: 'integer', minimum: 1 },
          },
        ],
        responses: {
          '200': {
            description: 'Linhas do relatório + metadados de execução',
            content: {
              'application/json': {
                schema: {
                  type: 'object',
                  properties: { data: { $ref: '#/components/schemas/ReportResult' } },
                },
              },
            },
          },
          '422': { description: 'reportType inválido ou filtros malformados' },
        },
      },
    },
  },
} as const;
