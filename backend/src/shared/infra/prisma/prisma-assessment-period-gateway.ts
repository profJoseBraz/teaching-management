import { NotFoundError, ValidationError } from '../../domain/errors';
import type { AssessmentPeriodGateway } from '../../application/ports/assessment-period-gateway';
import { prisma } from './prisma-client';

export class PrismaAssessmentPeriodGateway implements AssessmentPeriodGateway {
  async assertUsableForClass(input: {
    teacherId: string;
    classId: string;
    assessmentPeriodId: string;
  }): Promise<void> {
    const schoolClass = await prisma.class.findFirst({
      where: { id: input.classId, teacherId: input.teacherId, deletedAt: null },
      select: { academicYearId: true },
    });
    if (!schoolClass) {
      throw new ValidationError('Class not found for this teacher');
    }

    const period = await prisma.assessmentPeriod.findFirst({
      where: {
        id: input.assessmentPeriodId,
        teacherId: input.teacherId,
        deletedAt: null,
      },
      select: { academicYearId: true },
    });
    if (!period) {
      throw new NotFoundError('Assessment period not found');
    }

    if (period.academicYearId !== schoolClass.academicYearId) {
      throw new ValidationError('Assessment period does not belong to the class academic year');
    }
  }
}
