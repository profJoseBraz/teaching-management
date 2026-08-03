export type ActivityGroup = {
  id: string;
  teacherId: string;
  activityId: string;
  name: string;
  createdAt: Date;
  updatedAt: Date;
  deletedAt: Date | null;
};

export type ActivityGroupWithMembers = ActivityGroup & {
  studentIds: string[];
};
