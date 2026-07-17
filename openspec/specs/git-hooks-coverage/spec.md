# git-hooks-coverage Spec

> 后端 Git 钩子覆盖率门禁能力契约。
> 本 spec 定义 pre-commit / pre-push 钩子脚本与钩子安装脚本的行为。

## Requirements

### Requirement: Pre-commit hook script
The system SHALL provide a `pre-commit` hook script at `backend/hooks/pre-commit` that:
1. Checks if any staged files contain `.java` extension
2. If no Java files are staged, exits successfully with message "No Java files staged, skipping tests"
3. If Java files are staged, runs `mvn test -DexcludedGroups=slow` (fast tests only, excluding `@Tag("slow")`)
4. Supports `--no-verify` bypass (developer choice)

The pre-commit hook SHALL NOT run the JaCoCo coverage check: fast-only coverage (controller ~88%) cannot meet the 0.90 controller threshold because the `@Tag("slow")` controller tests are excluded. The coverage gate is enforced by the pre-push hook with the full test suite.

The hook script SHALL be executable (`chmod +x`).

#### Scenario: Commit with no Java files skips tests
- **WHEN** developer stages only markdown/yaml files and commits
- **THEN** pre-commit hook prints "No Java files staged, skipping tests" and exits 0

#### Scenario: Commit with Java files runs fast tests
- **WHEN** developer stages Java source files and commits
- **THEN** pre-commit hook runs fast tests (excluding @Tag("slow"))

#### Scenario: Fast test failure blocks commit
- **WHEN** any fast test fails during pre-commit
- **THEN** pre-commit hook exits non-zero, commit is aborted, developer sees test failure output

#### Scenario: --no-verify bypasses hook
- **WHEN** developer runs `git commit --no-verify`
- **THEN** pre-commit hook is skipped, commit proceeds regardless

### Requirement: Pre-push hook script
The system SHALL provide a `pre-push` hook script at `backend/hooks/pre-push` that:
1. Runs `mvn test` (all tests including `@Tag("slow")`)
2. If tests pass, runs `mvn jacoco:report jacoco:check`
3. Exits non-zero if either tests or coverage check fails

#### Scenario: Push runs full test suite + coverage
- **WHEN** developer pushes to remote
- **THEN** pre-push hook runs all tests (including @Tag("slow")) followed by JaCoCo coverage check

#### Scenario: Push blocked on test failure
- **WHEN** any test fails during pre-push
- **THEN** push is aborted, developer sees test failure output

### Requirement: Hook installation script
The system SHALL provide `backend/scripts/install-hooks.sh` that:
1. Detects the git hooks directory via `git rev-parse --git-dir`
2. Copies `backend/hooks/pre-commit` and `backend/hooks/pre-push` to the hooks directory
3. Sets executable permission on both scripts
4. Prints success message with hook locations
5. Works correctly in both standalone repos and git submodule scenarios

#### Scenario: Install hooks in submodule
- **WHEN** developer runs `./scripts/install-hooks.sh` from within `backend/` directory
- **THEN** hooks are installed to `.git/modules/backend/hooks/` (or equivalent git dir)

#### Scenario: Install hooks prints success
- **WHEN** installation completes successfully
- **THEN** script prints "Git hooks installed successfully" and lists installed hook paths
