# SecretSatan — instructions for coding agents

SecretSatan is a SwiftUI app (iOS (iPhone), iPadOS) written in Swift 6 language mode, with MVVM and a feature-based architecture. It is split into Swift packages.
Read the configuration file of the area you are working on before you change it, and follow it.

| Area | Path | Configuration |
|---|---|---|
| App scenes (features) | `SecretSatan/` | `SecretSatan/FEATURES.md`: feature anatomy, data flow, navigation and the app map |
| Data layer: repositories, services and local storage | `Packages/SecretSatanData/` | `Packages/SecretSatanData/DATA.md`: repositories, `Remote/` and `Local/`, protocols, DAOs, storages |
| Design system and UI components | `Packages/SecretSatanUI/` | `Packages/SecretSatanUI/DESIGN_SYSTEM.md`: tokens, components, `.localized(_:)` |

## Skills

Project skills live in `.claude/skills/`, which Claude Code and GitHub Copilot both read. Any other agent can follow the same steps by reading the SKILL.md files.

- `secretsatan-new-feature`: new scene. Run `python3 scripts/codegen/new_feature.py --name X --parent Y [--repository Z]`.
- `secretsatan-new-repo`: new repository. Asks remote or local (and the storage for local), then runs
  `python3 scripts/codegen/new_repo.py --name X --type remote|local [--storage json|swiftdata|userdefaults|keychain]`.

Always use the generators to create features and repositories, so the structure and the registries stay consistent.

## Rules

- SwiftUI only. Feature views compose `SecretSatanUI` components and never hard-code colors, fonts or spacing.
- Features reach `SecretSatanData` only through a repository's public protocol, from the feature's use case.
- New dependencies are injected through the feature's `<Feature>Dependencies`: a `private let` plus a `resolve<Name>()` function.
- Every function of a `<Feature>Dependencies` that hands out a dependency is named `resolve<Name>()` (`resolveUseCase()`, `resolveViewModel()`, `resolveRepository()`). Never use the `make` prefix.
- `View`, `ViewModel` and `UseCase` receive only `init(dependencies: <Feature>Dependencies)` and resolve the rest inside it.
- The use case returns only the data of the response, mapped into a `<Feature>ViewData` field type; the view model adds it to its own field of `viewData` (see FEATURES.md).
- SwiftLint runs on every build (`scripts/lint.sh`), and the build fails above **3 violations**.

## SwiftLint check for new code

Every time you add a variable, constant, property, function or method, check that it breaks no SwiftLint rule before you consider the change done. The 3-violation limit is a ceiling for the whole project, not a budget for new code: new code adds **zero** violations.

1. Write it with the rules in mind. The ones new declarations break most often:
   - `identifier_name`: lowerCamelCase, at least 3 characters (no `x`, `vm`, `tmp`), no leading underscores or snake_case.
   - `function_body_length`, `cyclomatic_complexity`, `function_parameter_count`: keep functions short and simple, and group many parameters into a type.
   - `line_length`: wrap long signatures and calls.
   - `force_cast`, `force_try`: use `as?` and `try` with real error handling.
   - `trailing_whitespace`, `vertical_whitespace`, `colon`, `comma`: standard Swift formatting.
2. Lint the files you touched right away, without waiting for a build:
   ```bash
   swiftlint lint --quiet path/to/File.swift   # one file
   scripts/lint.sh                             # whole project, same check as the build
   ```
3. If a violation points at your new declaration, fix the code (rename it, split the function, wrap the line). Do not silence it with `// swiftlint:disable` or by editing the SwiftLint configuration unless the user asks for it.
4. If SwiftLint is not installed, say so and review the code against the rules above by hand.

## Git flow

- `main` holds releases. `develop` is the integration branch.
- Every feature is built on `feature/SecretSatan-<Feature>`, created from `develop`.

## Build

```bash
xcodegen generate                      # creates SecretSatan.xcodeproj from project.yml (it is not committed)
open SecretSatan.xcodeproj
(cd Packages/SecretSatanData && swift test)  # package tests
```

## Keeping the new-project-ios skill in sync

This project was created with the `new-project-ios` skill, and the user wants every new project to start with the
conventions this one ends up with.

**When to ask.** When a change alters how the project is configured or how something must be done, ask the user
whether the `new-project-ios` skill should be updated with it. Ask once, when the change is done, in a short
question that names the change. This covers changes to:

- the rules and conventions in `AGENTS.md`, `SecretSatan/FEATURES.md`, `Packages/SecretSatanData/DATA.md` or
  `Packages/SecretSatanUI/DESIGN_SYSTEM.md` (code style, architecture, naming, navigation, localisation…);
- `.swiftlint.yml`, `.gitignore`, `project.yml` settings that every project needs, or `scripts/lint.sh`;
- the generators and templates in `scripts/codegen/`, or the project skills in `.claude/skills/`;
- the shared code of the packages (`Core/`, the `SecretSatanUI` components and localisation).

Do not ask for changes that only make sense in this app: its features, repositories, endpoints, design tokens,
assets, texts or the registries in the docs.

**If the user says yes**, update the skill with the `skill-creator` skill:

1. Start from the current `new-project-ios` skill, never from an older copy.
2. Generalise the change before copying it: replace `SecretSatan` with the `__PROJECT__` placeholder,
   `SecretSatanData` with `__DATA_MODULE__`, `SecretSatanUI` with `__UI_MODULE__` and
   `secretsatan` with `__PROJECT_SLUG__`, and leave out anything specific to this app.
3. Apply it to the matching files of the skill's `template/` (hidden files are stored as `dot-<name>`), and to its
   `SKILL.md` or `scripts/create_project.py` when the change affects them.
4. Generate a test project with the updated skill and check that the change comes out as expected.
5. Package the skill and give it to the user to save. Tell them what changed.

If the user says no, do nothing else.
