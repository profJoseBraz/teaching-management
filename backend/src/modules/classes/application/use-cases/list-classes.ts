import type { ClassWithDisciplines } from '../../domain/class';
import type { ClassDisciplineRepository } from '../ports/class-discipline-repository';
import type { ClassRepository, ListClassesFilters } from '../ports/class-repository';

export class ListClassesUseCase {
  constructor(
    private readonly classes: ClassRepository,
    private readonly classDisciplines: ClassDisciplineRepository,
  ) {}

  async execute(teacherId: string, filters?: ListClassesFilters): Promise<ClassWithDisciplines[]> {
    const classes = await this.classes.list(teacherId, filters);
    const linksByClass = await this.classDisciplines.listActiveByClasses(
      teacherId,
      classes.map((klass) => klass.id),
    );

    return classes.map((klass) => {
      const links = linksByClass.get(klass.id) ?? [];
      return {
        ...klass,
        disciplineIds: links.map((link) => link.disciplineId),
        disciplines: links.map((link) => ({ id: link.discipline.id, name: link.discipline.name })),
      };
    });
  }
}
