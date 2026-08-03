# Gestão Docente — Frontend (Flutter)

Aplicativo Flutter (Material 3, responsivo, tema claro/escuro) para o MVP de
**Gestão Docente**, consumindo a API REST do backend (`/api/v1`). Segue
Clean Architecture:

```
Screen (Presentation) → Provider (Riverpod) → Repository (Domain) → Datasource (Data) → API (Dio)
```

A camada de apresentação (widgets) nunca chama HTTP diretamente: toda tela lê
o estado através de um `Provider`/`StateNotifierProvider`, que delega a um
`Repository` (interface abstrata do domínio), implementado na camada de dados
por um `Datasource` que fala com o backend via `ApiClient` (Dio).

## Stack

| Camada         | Tecnologia                                   |
|----------------|-----------------------------------------------|
| Estado         | `flutter_riverpod`                            |
| HTTP           | `dio` (+ interceptor de autenticação JWT)     |
| Navegação      | `go_router` (shell com abas + guards de auth) |
| Persistência local | `shared_preferences` (preferências), `flutter_secure_storage` (tokens JWT) |
| Datas/i18n     | `intl` (pt_BR)                                |

## Pré-requisitos

- Flutter SDK 3.35+ (Dart ^3.12) — `flutter --version`
- Backend rodando em `http://localhost:3333/api/v1` (ver `backend/README.md`)
- Um dispositivo/emulador ou o Chrome/Windows habilitado (`flutter devices`)

## Como rodar

```bash
cd frontend
flutter pub get

# Web (Chrome) — mais simples para testar contra localhost:
flutter run -d chrome

# Windows desktop:
flutter run -d windows

# Android emulator/dispositivo físico:
flutter run -d <device-id>
```

> **Atenção (Android emulator):** o endpoint da API está fixado em
> `http://localhost:3333/api/v1` (`lib/core/network/api_client.dart`). No
> emulador padrão do Android, `localhost` do host não é acessível — troque
> para `http://10.0.2.2:3333/api/v1` nesse cenário.

### Login de demonstração

```
E-mail: professor@gestao.docente
Senha:  Professor@123
```

## Scripts úteis

```bash
flutter analyze     # lint estático — deve retornar 0 erros
flutter test        # roda o smoke test em test/widget_test.dart
flutter build apk    # build de release Android
flutter build web    # build de release Web
```

## Estrutura de pastas

```
lib/
  main.dart                 # bootstrap: SharedPreferences, ProviderScope, intl
  app.dart                  # MaterialApp.router + temas + GoRouter
  core/
    theme/app_theme.dart    # Material 3, seed teal (0xFF0F766E), light/dark
    router/app_router.dart  # go_router: rotas, shell com abas, guards de auth
    network/                # ApiClient (Dio), AuthInterceptor, TokenStorage
    errors/app_exception.dart
    widgets/                # LoadingState, ErrorState, EmptyState,
                             # AsyncValueWidget, StatusChip, AttentionCard,
                             # AttendanceToggle, AppScaffold (shell responsivo)
  domain/
    entities/                # modelos puros (User, SchoolClass, Lesson, ...)
    repositories/            # interfaces abstratas (contrato do domínio)
  data/
    datasources/             # chamadas HTTP reais via ApiClient + parsing JSON
    repositories/             # implementações que delegam ao datasource
  presentation/
    providers/                # Riverpod: sessão, ano letivo, turmas, alunos,
                               # aulas, conteúdos, frequência, atividades,
                               # dashboard, relatórios, tema
    screens/                  # uma pasta por módulo (auth, dashboard,
                               # classes, lessons, attendance, contents,
                               # activities, students, reports, settings)
```

## Telas implementadas

| Tela | Rota | Descrição |
|------|------|-----------|
| Splash | `/splash` | Checa sessão existente (token salvo) antes de decidir a rota inicial |
| Login | `/login` | E-mail/senha, validação, mensagens de erro, credenciais demo |
| Dashboard | `/dashboard` | Lista de `AttentionItem` (pendências) — cards clicáveis por severidade, resumo do período |
| Turmas | `/classes` | Lista de turmas do ano letivo selecionado + criação (seleção múltipla de disciplinas) |
| Detalhe da turma | `/classes/:id` | Seletor de disciplina (quando a turma tem mais de uma) + gerenciamento de vínculos + abas: **Aulas**, **Frequência**, **Conteúdos**, **Atividades**, **Alunos** (matrícula/desmatrícula) |
| Frequência (chamada) | `/classes/:id/lessons/:lessonId/attendance` | Carrega ficha, alterna PRESENTE/FALTA/ATRASO por aluno, salva em lote, conclui a chamada |
| Atividades — detalhe | `/classes/:id/activities/:activityId` | Resumo de entregas, lançamento de nota individual/em grupo |
| Alunos | `/students` | CRUD com busca |
| Relatórios | `/reports` | Escolha de tipo de relatório + filtros (ano, turma, período, limiar) → tabela de resultados |
| Configurações | `/settings` | CRUD de anos letivos, cursos, disciplinas e períodos avaliativos; preferência de tema; logout |

Todas as telas cobrem explicitamente os 4 estados: **Loading**, **Error**
(com retry), **Empty** (com mensagem contextual) e **Success**, através do
widget compartilhado `AsyncValueWidget`.

## Autenticação e sessão

- Tokens (`accessToken`/`refreshToken`) são persistidos em
  `flutter_secure_storage` (`TokenStorage`).
- `AuthInterceptor` injeta `Authorization: Bearer <accessToken>` em toda
  requisição autenticada e, ao receber `401`, limpa os tokens e notifica a
  aplicação (`SessionEvents`) para forçar logout.
- `go_router` observa `authNotifierProvider` (`refreshListenable`) e
  redireciona automaticamente: sem sessão → `/login`; sessão válida em
  `/login` ou `/splash` → `/dashboard`.

## Turmas com múltiplas disciplinas

Uma turma pode ministrar **mais de uma disciplina** simultaneamente
(vínculo N:N, refletido em `SchoolClass.disciplineIds`/`disciplines`):

- **Criação**: o formulário de nova turma usa seleção múltipla (`FilterChip`)
  — é obrigatório escolher ao menos uma disciplina.
- **Detalhe da turma**: o botão de disciplinas na `AppBar` abre um diálogo de
  vínculo (`CheckboxListTile`) para adicionar/remover disciplinas da turma
  (`GET`/`POST`/`DELETE /classes/:classId/disciplines`), sempre mantendo ao
  menos uma vinculada.
- **Filtro por disciplina**: quando a turma tem mais de uma disciplina, uma
  barra de chips ("Todas as disciplinas" + uma por disciplina vinculada)
  aparece no topo do detalhe e filtra as abas Aulas, Conteúdos e Atividades
  (`?disciplineId=`).
- **Aulas** e **Conteúdos** exigem a escolha de uma disciplina (dentre as
  vinculadas à turma) no momento da criação. **Atividades** têm um seletor
  opcional — quando não informado, o backend herda a disciplina da aula de
  origem.

## Seletor de ano letivo

O `AppBar` do shell principal (`AppScaffold`) expõe um seletor global de ano
letivo (`selectedAcademicYearIdProvider`), carregado via
`GET /academic-years` e priorizando o ano marcado como `isCurrent`. A seleção
é usada para filtrar turmas, dashboard e relatórios.

## Convenções de API assumidas

- Sucesso: `{ "data": ... }`
- Erro: `{ "error": { "code": "...", "message": "..." } }`
- Autenticação: header `Authorization: Bearer <accessToken>`

Erros de rede/API são normalizados em `AppException` (`core/errors`), que os
widgets de erro exibem com opção de "Tentar novamente".

## Qualidade

- `flutter analyze`: **0 erros, 0 warnings** (apenas avisos informativos
  estilísticos, ex.: sugestões de sintaxe null-aware mais recente do Dart).
- `flutter test`: smoke test garante que o app inicializa e constrói a árvore
  de widgets sem exceções.
