export const USER_ROLES = ['PROFESSOR', 'ADMIN', 'COORDINATOR', 'SECRETARY'] as const;

export type UserRole = (typeof USER_ROLES)[number];
