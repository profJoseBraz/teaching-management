import type { EnrollmentGateway } from '../../../../shared/application/ports/enrollment-gateway';
import { NotFoundError, ValidationError } from '../../../../shared/domain/errors';
import type { ActivityGroupWithMembers } from '../../domain/activity-group';
import type { ActivityRepository } from '../ports/activity-repository';
import type { ActivityGroupRepository, GroupInput } from '../ports/activity-group-repository';
import type { SubmissionRepository } from '../ports/submission-repository';

export class CreateActivityGroupsUseCase {
  constructor(
    private readonly activities: ActivityRepository,
    private readonly activityGroups: ActivityGroupRepository,
    private readonly submissions: SubmissionRepository,
    private readonly enrollments: EnrollmentGateway,
  ) {}

  async execute(
    activityId: string,
    teacherId: string,
    groups: GroupInput[],
  ): Promise<ActivityGroupWithMembers[]> {
    const activity = await this.activities.findById(activityId, teacherId);
    if (!activity) {
      throw new NotFoundError('Activity not found');
    }

    if (activity.mode !== 'GROUP') {
      throw new ValidationError('Groups can only be assigned to activities with mode GROUP');
    }

    const allStudentIds = groups.flatMap((group) => group.studentIds);
    const uniqueStudentIds = new Set(allStudentIds);
    if (uniqueStudentIds.size !== allStudentIds.length) {
      throw new ValidationError('A student cannot belong to more than one group in the same activity');
    }

    const allActive = await this.enrollments.areAllStudentsActiveInClass(activity.classId, allStudentIds);
    if (!allActive) {
      throw new ValidationError('Some students do not have an active enrollment in this class');
    }

    const createdGroups = await this.activityGroups.replaceGroups(activityId, teacherId, groups);

    for (const group of createdGroups) {
      if (group.studentIds.length === 0) {
        continue;
      }
      const groupSubmissions = await this.submissions.findByActivityAndStudents(
        activityId,
        teacherId,
        group.studentIds,
      );
      await this.submissions.assignGroup(
        groupSubmissions.map((submission) => submission.id),
        group.id,
      );
    }

    return createdGroups;
  }
}
