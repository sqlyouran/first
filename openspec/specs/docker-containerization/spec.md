# docker-containerization Specification

## Purpose
TBD - created by archiving change production-deployment. Update Purpose after archive.
## Requirements
### Requirement: Backend Dockerfile multi-stage build
The system SHALL provide a `backend/Dockerfile` that uses multi-stage build to produce a minimal JRE 17 runtime image from the Spring Boot fat jar.

#### Scenario: Build stage compiles fat jar
- **WHEN** `docker build` is executed for the backend
- **THEN** the build stage uses `maven:3.9-eclipse-temurin-17-focal` to run `mvn package -DskipTests` and produce `app.jar`

#### Scenario: Run stage uses minimal JRE image
- **WHEN** the build completes
- **THEN** the run stage uses `eclipse-temurin:17-jre-jammy` with `java -jar app.jar`, exposing port 8080

#### Scenario: Container starts Spring Boot application
- **WHEN** the backend container starts
- **THEN** Spring Boot listens on port 8080 and accepts HTTP requests

### Requirement: Frontend Dockerfile multi-stage build
The system SHALL provide a `frontend/Dockerfile` that uses Next.js standalone output mode for minimal runtime image.

#### Scenario: Build stage compiles Next.js standalone
- **WHEN** `docker build` is executed for the frontend
- **THEN** the build stage uses `node:20-alpine`, runs `npm ci` and `npm run build`, producing standalone output in `.next/standalone/`

#### Scenario: Run stage copies standalone output
- **WHEN** the build completes
- **THEN** the run stage uses `node:20-alpine`, copies `.next/standalone/` and `.next/static/` and `public/`, starts with `node server.js` on port 3000

#### Scenario: Container serves Next.js SSR pages
- **WHEN** the frontend container starts
- **THEN** Next.js serves SSR pages on port 3000 and accepts HTTP requests

### Requirement: Frontend standalone output configuration
The system SHALL configure `frontend/next.config.ts` to enable standalone output for containerized deployment.

#### Scenario: next.config.ts enables standalone
- **WHEN** the frontend is built
- **THEN** `next.config.ts` contains `output: 'standalone'` in the config object

#### Scenario: Rewrites use environment variable
- **WHEN** the frontend processes API rewrite rules
- **THEN** the rewrite destination uses `process.env.BACKEND_URL || "http://localhost:8080"` instead of hardcoded `http://localhost:8080`

### Requirement: Backend Redis environment variable
The system SHALL configure Redis host as an environment variable in `application.yml` instead of hardcoded `localhost`.

#### Scenario: Redis host reads from environment variable
- **WHEN** Spring Boot starts with `REDIS_HOST=redis`
- **THEN** Redis connection uses host `redis` instead of `localhost`

#### Scenario: Default value preserves local development
- **WHEN** Spring Boot starts without `REDIS_HOST` set
- **THEN** Redis connection falls back to `localhost` (backward compatible)

