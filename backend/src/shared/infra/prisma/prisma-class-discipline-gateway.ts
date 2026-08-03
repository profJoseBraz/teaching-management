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
}
