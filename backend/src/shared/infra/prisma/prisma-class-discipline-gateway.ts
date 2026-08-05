import type { ClassDisciplineGateway } from '../../application/ports/class-discipline-gateway';
import { prisma } from './prisma-client';

export class PrismaClassDisciplineGateway implements ClassDisciplineGateway {
  async isLinked(teacherId: string, classId: string, disciplineId: string): Promise<boolean> {
    const found = await prisma.classDiscipline.findFirst({
      where: { teacherId, classId, disciplineId, deletedAt: null },
      select: { id: true },
    });
    return found !== null;
  }

  async areAllLinked(teacherId: string, classId: string, disciplineIds: string[]): Promise<boolean> {
    const unique = [...new Set(disciplineIds)];
    if (unique.length === 0) {
      return false;
    }

    const count = await prisma.classDiscipline.count({
      where: {
        teacherId,
        classId,
        disciplineId: { in: unique },
        deletedAt: null,
      },
    });
    return count === unique.length;
  }
}
