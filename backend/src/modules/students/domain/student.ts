export type Student = {
  id: string;
  teacherId: string;
  name: string;
  registryCode: string | null;
  email: string | null;
  phone: string | null;
  notes: string | null;
  createdAt: Date;
  updatedAt: Date;
  deletedAt: Date | null;
};
