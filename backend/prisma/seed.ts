import { PrismaClient, AttendanceStatus, SubmissionStatus } from '@prisma/client';
import bcrypt from 'bcryptjs';

const prisma = new PrismaClient();

async function main() {
  const email = 'professor@gestao.docente';
  const passwordHash = await bcrypt.hash('Professor@123', 10);

  const teacher = await prisma.user.upsert({
    where: { email },
    update: {
      name: 'Professor Demo',
      passwordHash,
      isActive: true,
      deletedAt: null,
    },
    create: {
      name: 'Professor Demo',
      email,
      passwordHash,
      role: 'PROFESSOR',
    },
  });

  const year = await prisma.academicYear.upsert({
    where: {
      teacherId_year: {
        teacherId: teacher.id,
        year: 2026,
      },
    },
    update: { isCurrent: true, label: 'Ano Letivo 2026' },
    create: {
      teacherId: teacher.id,
      year: 2026,
      label: 'Ano Letivo 2026',
      isCurrent: true,
      startsOn: new Date('2026-02-01'),
      endsOn: new Date('2026-12-15'),
    },
  });

  await prisma.academicYear.updateMany({
    where: {
      teacherId: teacher.id,
      id: { not: year.id },
    },
    data: { isCurrent: false },
  });

  const course = await prisma.course.upsert({
    where: {
      teacherId_name: {
        teacherId: teacher.id,
        name: 'Desenvolvimento de Sistemas',
      },
    },
    update: {},
    create: {
      teacherId: teacher.id,
      name: 'Desenvolvimento de Sistemas',
      description: 'Curso técnico em Desenvolvimento de Sistemas',
    },
  });

  const discipline = await prisma.discipline.upsert({
    where: {
      teacherId_name: {
        teacherId: teacher.id,
        name: 'Banco de Dados',
      },
    },
    update: {},
    create: {
      teacherId: teacher.id,
      name: 'Banco de Dados',
      description: 'Modelagem, SQL e administração básica',
    },
  });

  const secondDiscipline = await prisma.discipline.upsert({
    where: {
      teacherId_name: {
        teacherId: teacher.id,
        name: 'Programação Web',
      },
    },
    update: {},
    create: {
      teacherId: teacher.id,
      name: 'Programação Web',
      description: 'HTML, CSS, JavaScript e frameworks front-end',
    },
  });

  await prisma.courseDiscipline.upsert({
    where: {
      courseId_disciplineId: {
        courseId: course.id,
        disciplineId: discipline.id,
      },
    },
    update: { deletedAt: null },
    create: {
      teacherId: teacher.id,
      courseId: course.id,
      disciplineId: discipline.id,
    },
  });

  await prisma.courseDiscipline.upsert({
    where: {
      courseId_disciplineId: {
        courseId: course.id,
        disciplineId: secondDiscipline.id,
      },
    },
    update: { deletedAt: null },
    create: {
      teacherId: teacher.id,
      courseId: course.id,
      disciplineId: secondDiscipline.id,
    },
  });

  const periods = [
    { name: '1º Bimestre', sortOrder: 1, startsOn: new Date('2026-02-01'), endsOn: new Date('2026-04-30') },
    { name: '2º Bimestre', sortOrder: 2, startsOn: new Date('2026-05-01'), endsOn: new Date('2026-07-15') },
    { name: 'Recuperação', sortOrder: 3, startsOn: new Date('2026-07-16'), endsOn: new Date('2026-07-31') },
  ];

  for (const period of periods) {
    const existing = await prisma.assessmentPeriod.findFirst({
      where: {
        teacherId: teacher.id,
        academicYearId: year.id,
        name: period.name,
        deletedAt: null,
      },
    });

    if (existing) {
      await prisma.assessmentPeriod.update({
        where: { id: existing.id },
        data: period,
      });
    } else {
      await prisma.assessmentPeriod.create({
        data: {
          teacherId: teacher.id,
          academicYearId: year.id,
          ...period,
        },
      });
    }
  }

  const firstPeriod = await prisma.assessmentPeriod.findFirstOrThrow({
    where: {
      teacherId: teacher.id,
      academicYearId: year.id,
      name: '1º Bimestre',
      deletedAt: null,
    },
  });

  let classEntity = await prisma.class.findFirst({
    where: {
      teacherId: teacher.id,
      academicYearId: year.id,
      courseId: course.id,
      name: '3º DS - Manhã',
      deletedAt: null,
    },
  });

  if (!classEntity) {
    classEntity = await prisma.class.create({
      data: {
        teacherId: teacher.id,
        academicYearId: year.id,
        courseId: course.id,
        name: '3º DS - Manhã',
        shift: 'MORNING',
        status: 'ACTIVE',
      },
    });
  }

  // Turma ministra duas disciplinas (demonstra N:N via ClassDiscipline).
  for (const linkedDiscipline of [discipline, secondDiscipline]) {
    await prisma.classDiscipline.upsert({
      where: {
        classId_disciplineId: {
          classId: classEntity.id,
          disciplineId: linkedDiscipline.id,
        },
      },
      update: { deletedAt: null },
      create: {
        teacherId: teacher.id,
        classId: classEntity.id,
        disciplineId: linkedDiscipline.id,
      },
    });
  }

  const studentNames = [
    { name: 'Ana Souza', registryCode: '2026001' },
    { name: 'Bruno Lima', registryCode: '2026002' },
    { name: 'Carla Mendes', registryCode: '2026003' },
    { name: 'Diego Alves', registryCode: '2026004' },
    { name: 'Eduarda Nunes', registryCode: '2026005' },
  ];

  const students = [];
  for (const item of studentNames) {
    let student = await prisma.student.findFirst({
      where: {
        teacherId: teacher.id,
        registryCode: item.registryCode,
        deletedAt: null,
      },
    });

    if (!student) {
      student = await prisma.student.create({
        data: {
          teacherId: teacher.id,
          name: item.name,
          registryCode: item.registryCode,
        },
      });
    }

    students.push(student);

    await prisma.enrollment.upsert({
      where: {
        classId_studentId: {
          classId: classEntity.id,
          studentId: student.id,
        },
      },
      update: { status: 'ACTIVE', deletedAt: null },
      create: {
        teacherId: teacher.id,
        classId: classEntity.id,
        studentId: student.id,
        status: 'ACTIVE',
      },
    });
  }

  let lessonWithoutAttendance = await prisma.lesson.findFirst({
    where: {
      teacherId: teacher.id,
      classId: classEntity.id,
      date: new Date('2026-03-10'),
      deletedAt: null,
    },
  });

  if (!lessonWithoutAttendance) {
    lessonWithoutAttendance = await prisma.lesson.create({
      data: {
        teacherId: teacher.id,
        classId: classEntity.id,
        disciplineId: discipline.id,
        date: new Date('2026-03-10'),
        startTime: '08:00',
        endTime: '09:40',
        observations: 'Aula sem frequência — pendência do Dashboard',
        attendanceCompleted: false,
      },
    });
  }

  let lessonWithAttendance = await prisma.lesson.findFirst({
    where: {
      teacherId: teacher.id,
      classId: classEntity.id,
      date: new Date('2026-03-12'),
      deletedAt: null,
    },
  });

  if (!lessonWithAttendance) {
    lessonWithAttendance = await prisma.lesson.create({
      data: {
        teacherId: teacher.id,
        classId: classEntity.id,
        disciplineId: discipline.id,
        date: new Date('2026-03-12'),
        startTime: '08:00',
        endTime: '09:40',
        observations: 'Introdução a SQL',
        attendanceCompleted: true,
      },
    });
  }

  for (const [index, student] of students.entries()) {
    const status: AttendanceStatus =
      index === 2 ? AttendanceStatus.ABSENT : index === 3 ? AttendanceStatus.LATE : AttendanceStatus.PRESENT;

    await prisma.attendance.upsert({
      where: {
        lessonId_studentId: {
          lessonId: lessonWithAttendance.id,
          studentId: student.id,
        },
      },
      update: { status },
      create: {
        teacherId: teacher.id,
        lessonId: lessonWithAttendance.id,
        studentId: student.id,
        status,
      },
    });
  }

  let content = await prisma.content.findFirst({
    where: {
      teacherId: teacher.id,
      classId: classEntity.id,
      title: 'Introdução ao SQL',
      deletedAt: null,
    },
  });

  if (!content) {
    content = await prisma.content.create({
      data: {
        teacherId: teacher.id,
        classId: classEntity.id,
        disciplineId: discipline.id,
        title: 'Introdução ao SQL',
        description: 'SELECT, WHERE e ORDER BY',
        status: 'IN_PROGRESS',
      },
    });
  }

  await prisma.lessonContent.upsert({
    where: {
      lessonId_contentId: {
        lessonId: lessonWithAttendance.id,
        contentId: content.id,
      },
    },
    update: {},
    create: {
      lessonId: lessonWithAttendance.id,
      contentId: content.id,
    },
  });

  let activity = await prisma.activity.findFirst({
    where: {
      teacherId: teacher.id,
      classId: classEntity.id,
      title: 'Lista 1 — Consultas SQL',
      deletedAt: null,
    },
  });

  if (!activity) {
    activity = await prisma.activity.create({
      data: {
        teacherId: teacher.id,
        classId: classEntity.id,
        originLessonId: lessonWithAttendance.id,
        assessmentPeriodId: firstPeriod.id,
        title: 'Lista 1 — Consultas SQL',
        description: 'Resolver as 10 consultas do material',
        category: 'EXERCISE',
        mode: 'INDIVIDUAL',
        gradeMode: 'INDIVIDUAL',
        maxScore: 100,
        createdOn: new Date('2026-03-12'),
        dueDate: new Date('2026-03-20'),
        activityDisciplines: {
          create: [{ teacherId: teacher.id, disciplineId: discipline.id }],
        },
      },
    });
  }

  for (const [index, student] of students.entries()) {
    const status: SubmissionStatus =
      index < 2 ? SubmissionStatus.SUBMITTED : index === 2 ? SubmissionStatus.PENDING : SubmissionStatus.PENDING;

    await prisma.submission.upsert({
      where: {
        activityId_studentId: {
          activityId: activity.id,
          studentId: student.id,
        },
      },
      update: { status },
      create: {
        teacherId: teacher.id,
        activityId: activity.id,
        studentId: student.id,
        status,
        submittedAt: status === SubmissionStatus.SUBMITTED ? new Date('2026-03-18') : null,
      },
    });
  }

  console.log('Seed completed');
  console.log(`Teacher login: ${email} / Professor@123`);
}

main()
  .catch((error) => {
    console.error(error);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
