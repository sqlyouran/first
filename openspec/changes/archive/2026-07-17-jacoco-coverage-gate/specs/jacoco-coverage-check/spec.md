## ADDED Requirements

### Requirement: JaCoCo Maven plugin integration
The system SHALL include `jacoco-maven-plugin 0.8.12` in `pom.xml` with three execution goals:
1. `prepare-agent` bound to `initialize` phase — injects the JaCoCo Java agent into the JVM for coverage collection
2. `report` bound to `verify` phase — generates HTML/CSV/XML coverage reports at `target/site/jacoco/`
3. `check` bound to `verify` phase — evaluates coverage rules and fails the build if any rule is violated

The plugin SHALL be configured in `<pluginManagement>` (version pin) and `<plugins>` (execution config) sections.

#### Scenario: mvn verify runs JaCoCo report generation
- **WHEN** developer runs `mvn verify`
- **THEN** JaCoCo coverage report is generated at `backend/target/site/jacoco/index.html`

#### Scenario: mvn verify evaluates coverage rules
- **WHEN** developer runs `mvn verify`
- **THEN** JaCoCo evaluates all configured coverage rules and prints pass/fail for each rule

### Requirement: Layered coverage threshold rules
The system SHALL enforce three categories of coverage rules:

1. **BUNDLE rule** (global): LINE coverage ≥ 0.70 (Phase 1)
2. **PACKAGE rule** for `com.mooc.app.service`: LINE coverage ≥ 0.55 (Phase 1)
3. **PACKAGE rule** for `com.mooc.app.controller`: LINE coverage ≥ 0.90 (Phase 1)

Phase 2 thresholds (after 2 weeks): BUNDLE ≥ 0.75, service ≥ 0.65, controller ≥ 0.90
Phase 3 thresholds (after 1 month): BUNDLE ≥ 0.80, service ≥ 0.75, controller ≥ 0.90

#### Scenario: Coverage meets Phase 1 thresholds
- **WHEN** developer runs `mvn verify` and all coverage metrics meet or exceed Phase 1 thresholds
- **THEN** build succeeds with no JaCoCo violations

#### Scenario: Coverage below service threshold
- **WHEN** developer runs `mvn verify` and service package LINE coverage is below 0.55
- **THEN** build fails with JaCoCo violation message indicating service package LINE coverage rule was violated

#### Scenario: Coverage below global threshold
- **WHEN** developer runs `mvn verify` and BUNDLE LINE coverage is below 0.70
- **THEN** build fails with JaCoCo violation message indicating BUNDLE LINE coverage rule was violated

### Requirement: Coverage exclusion rules
The system SHALL exclude the following from coverage measurement:
- `com.mooc.app.AppApplication` — Spring Boot entry point
- `com.mooc.app.config.*` — Spring configuration classes
- `com.mooc.app.dto.*` — Data transfer objects (records with auto-generated getters)

Exclusions SHALL be configured via JaCoCo `<excludes>` in the `<configuration>` block.

#### Scenario: Excluded classes not counted in coverage
- **WHEN** JaCoCo generates coverage report
- **THEN** `AppApplication`, all classes in `config/` and `dto/` packages are excluded from coverage calculation

#### Scenario: Excluded classes do not affect threshold evaluation
- **WHEN** JaCoCo evaluates coverage rules
- **THEN** excluded classes do not contribute to line counts or coverage percentages for any rule
