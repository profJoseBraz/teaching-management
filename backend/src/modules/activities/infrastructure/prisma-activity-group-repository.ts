import { prisma } from '../../../shared/infra/prisma/prisma-client';
import type { ActivityGroupWithMembers } from '../domain/activity-group';
import type {
  ActivityGroupRepository,
  GroupInput,
} from '../application/ports/activity-group-repository';

export class PrismaActivityGroupRepository implements ActivityGroupRepository {
  async replaceGroups(
    activityId: string,
    teacherId: string,
    groups: GroupInput[],
  ): Promise<ActivityGroupWithMembers[]> {
    return prisma.$transaction(async (tx) => {
      const existingGroups = await tx.activityGroup.findMany({
        where: { activityId, teacherId, deletedAt: null },
        select: { id: true },
      });
      const existingGroupIds = existingGroups.map((group) => group.id);

      if (existingGroupIds.length > 0) {
        await tx.submission.updateMany({
          where: { groupId: { in: existingGroupIds } },
          data: { groupId: null },
        });
        await tx.activityGroupMember.deleteMany({
          where: { groupId: { in: existingGroupIds } },
        });
        await tx.activityGroup.updateMany({
          where: { id: { in: existingGroupIds } },
          data: { deletedAt: new Date() },
        });
      }

      const createdGroups: ActivityGroupWithMembers[] = [];
      for (const group of groups) {
        const created = await tx.activityGroup.create({
          data: {
            teacherId,
            activityId,
            name: group.name,
            members: {
              create: group.studentIds.map((studentId) => ({ studentId })),
            },
          },
          include: { members: true },
        });

        createdGroups.push({
          id: created.id,
          teacherId: created.teacherId,
          activityId: created.activityId,
          name: created.name,
          createdAt: created.createdAt,
          updatedAt: created.updatedAt,
          deletedAt: created.deletedAt,
          studentIds: created.members.map((member) => member.studentId),
        });
      }

      return createdGroups;
    });
  }

  async findById(id: string, teacherId: string): Promise<ActivityGroupWithMembers | null> {
    const row = await prisma.activityGroup.findFirst({
      where: { id, teacherId, deletedAt: null },
      include: { members: true },
    });

    if (!row) {
      return null;
    }

    return {
      id: row.id,
      teacherId: row.teacherId,
      activityId: row.activityId,
      name: row.name,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      deletedAt: row.deletedAt,
      studentIds: row.members.map((member) => member.studentId),
    };
  }
}
