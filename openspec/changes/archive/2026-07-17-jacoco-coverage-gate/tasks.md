## 1. JaCoCo Maven Plugin Setup

- [x] 1.1 Add `jacoco-maven-plugin 0.8.12` to `pom.xml` pluginManagement section (version pin)
- [x] 1.2 Configure three execution goals in plugins section: `prepare-agent` (initialize), `report` (verify), `check` (verify)
- [x] 1.3 Configure `<excludes>` to skip `AppApplication`, `config/**`, `dto/**`
- [x] 1.4 Run `mvn verify` to validate JaCoCo report generation at `target/site/jacoco/`

## 2. Coverage Threshold Rules

- [x] 2.1 Add BUNDLE rule: LINE coverage ≥ 0.70 (global Phase 1)
- [x] 2.2 Add PACKAGE rule for `com.mooc.app.service`: LINE coverage ≥ 0.55
- [x] 2.3 Add PACKAGE rule for `com.mooc.app.controller`: LINE coverage ≥ 0.90
- [x] 2.4 Run `mvn verify` to confirm all rules pass with current baseline (75.1% global / 59.5% service / 98.5% controller)

## 3. Slow Test Tagging

- [x] 3.1 Add `@Tag("slow")` to `BookmarkControllerTest` class
- [x] 3.2 Add `@Tag("slow")` to `CommentControllerTest` class
- [x] 3.3 Add `@Tag("slow")` to `SpotBookmarkControllerTest` class
- [x] 3.4 Add `@Tag("slow")` to `SpotCommentControllerTest` class
- [x] 3.5 Add `@Tag("slow")` to `AiChatServiceRagTest` class
- [x] 3.6 Run `mvn test -DexcludedGroups=slow` to verify slow tests are excluded
- [x] 3.7 Run `mvn test` (no filter) to verify all tests still pass including tagged ones

## 4. Git Hook Scripts

- [x] 4.1 Create `backend/hooks/pre-commit` script with Java file detection + fast test (`-Dgroups='!slow'`) + JaCoCo check
- [x] 4.2 Create `backend/hooks/pre-push` script with full test suite + JaCoCo check
- [x] 4.3 Create `backend/scripts/install-hooks.sh` that copies hooks to `$(git rev-parse --git-dir)/hooks/` and sets executable permission
- [x] 4.4 Make all scripts executable (`chmod +x`)

## 5. Hook Validation

- [x] 5.1 Run `./scripts/install-hooks.sh` to install hooks locally
- [x] 5.2 Test pre-commit with no Java files staged → should skip with message
- [x] 5.3 Test pre-commit with Java files staged → should run fast tests + coverage check
- [x] 5.4 Test `git commit --no-verify` → should bypass hooks

## 6. Documentation & Verification

- [x] 6.1 Run full test suite with `mvn verify` → confirm all 540 tests pass + JaCoCo report generated + coverage rules pass
- [ ] 6.2 Archive change: `openspec archive "jacoco-coverage-gate"`
