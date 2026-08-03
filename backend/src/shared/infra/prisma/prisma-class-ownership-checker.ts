import type { ClassOwnershipChecker } from '../../application/ports/class-ownership-checker';
import { prisma } from './prisma-client';

export class PrismaClassOwnershipChecker implements ClassOwnershipChecker {
  async isOwnedByTeacher(classId: string, teacherId: string): Promise<boolean> {
    const found = await prisma.class.findFirst({
      where: { id: classId, teacherId, deletedAt: null },
      select: { id: true },
    });
    return found !== null;
  }
}
