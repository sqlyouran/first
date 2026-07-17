## ADDED Requirements

### Requirement: @Tag("slow") annotation on DirtiesContext tests
The following test classes SHALL be annotated with `@Tag("slow")` at the class level:
- `BookmarkControllerTest` (13 test cases, ~33.8s)
- `CommentControllerTest` (12 test cases, ~20.6s)
- `SpotBookmarkControllerTest` (8 test cases, ~7.9s)
- `SpotCommentControllerTest` (6 test cases, ~7.0s)
- `AiChatServiceRagTest` (3 test cases, ~2.1s)

These classes use `@DirtiesContext` which forces Spring context restart on each test. Tagging them allows selective exclusion during fast test runs.

The `@Tag` annotation SHALL NOT alter test behavior, execution order, or assertions — it is purely a classification marker.

#### Scenario: mvn test excludes slow tests
- **WHEN** developer runs `mvn test -Dgroups='!slow'`
- **THEN** tests tagged with `@Tag("slow")` are excluded from execution; only untagged tests run

#### Scenario: mvn test includes all tests by default
- **WHEN** developer runs `mvn test` without group filters
- **THEN** all tests run, including those tagged with `@Tag("slow")`

#### Scenario: Slow tagged tests still pass when run
- **WHEN** developer runs `mvn test` (no exclusion) and slow tagged tests execute
- **THEN** all slow tagged tests pass with same assertions as before tagging

### Requirement: Surefire plugin group filter support
The Maven Surefire plugin SHALL be configured to support `-Dgroups` and `-DexcludedGroups` parameters for JUnit 5 tag filtering.

The existing surefire-plugin configuration SHALL NOT require modification — JUnit 5 platform support is already enabled via `<groupId>org.junit.jupiter</groupId>` dependency.

#### Scenario: -DexcludedGroups=slow skips tagged tests
- **WHEN** developer runs `mvn test -DexcludedGroups=slow`
- **THEN** all `@Tag("slow")` test classes are excluded; untagged tests run normally

#### Scenario: -Dgroups=slow runs only tagged tests
- **WHEN** developer runs `mvn test -Dgroups=slow`
- **THEN** only `@Tag("slow")` test classes execute; untagged tests are skipped
