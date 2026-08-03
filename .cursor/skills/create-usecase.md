# Create UseCase

Quando solicitado:

Create UseCase <Nome>

Criar um Caso de Uso seguindo Clean Architecture.

## Gerar

- Classe do UseCase
- Interface (quando necessário)
- Injeção de Dependências
- Regras de negócio
- Tratamento de erros
- Testes Unitários

## Sempre verificar

- Responsabilidade única
- SOLID
- Clean Architecture
- Regras de negócio centralizadas
- Independência da infraestrutura

Um UseCase nunca deve conhecer detalhes do banco de dados, do framework ou da interface do usuário.

Toda regra de negócio deve estar concentrada nos UseCases.
