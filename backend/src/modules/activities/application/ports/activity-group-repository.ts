import type { ActivityGroupWithMembers } from '../../domain/activity-group';

export type GroupInput = {
  name: string;
  studentIds: string[];
};

export interface ActivityGroupRepository {
  /** Substitui (soft-delete das antigas + criação das novas) todos os grupos de uma atividade. */
  replaceGroups(
    activityId: string,
    teacherId: string,
    groups: GroupInput[],
  ): Promise<ActivityGroupWithMembers[]>;
  findById(id: string, teacherId: string): Promise<ActivityGroupWithMembers | null>;
}
