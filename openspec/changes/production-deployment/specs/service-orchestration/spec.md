## ADDED Requirements

### Requirement: Docker Compose orchestrates all services
The system SHALL provide a `docker-compose.yml` at the project root that orchestrates all required services: nginx, backend, frontend, redis, chroma.

#### Scenario: All services start with single command
- **WHEN** `docker compose up -d` is executed
- **THEN** all 5 services (nginx, backend, frontend, redis, chroma) start in dependency order

#### Scenario: Services use Docker internal network
- **WHEN** services communicate with each other
- **THEN** they use Docker service names (e.g., `backend`, `redis`, `chroma`) as hostnames instead of `localhost`

### Requirement: Service dependency ordering
The system SHALL define correct startup dependencies between services.

#### Scenario: Nginx starts after frontend and backend
- **WHEN** docker compose starts services
- **THEN** nginx `depends_on` frontend and backend, ensuring they are ready before nginx accepts traffic

#### Scenario: Backend starts after redis
- **WHEN** docker compose starts services
- **THEN** backend `depends_on` redis

#### Scenario: Frontend starts after backend
- **WHEN** docker compose starts services
- **THEN** frontend `depends_on` backend (for SSR data fetching)

### Requirement: Data persistence via Docker volumes
The system SHALL use Docker named volumes for stateful services to survive container restarts.

#### Scenario: Redis data persists across restarts
- **WHEN** the redis container restarts
- **THEN** Redis data in `/data` is preserved via named volume `redis_data`

#### Scenario: Chroma vector data persists across restarts
- **WHEN** the chroma container restarts
- **THEN** Chroma data in `/chroma/chroma` is preserved via named volume `chroma_data`

### Requirement: Production environment variables
The system SHALL load production environment variables from `.env.production` file.

#### Scenario: Backend reads production env
- **WHEN** backend container starts
- **THEN** it loads variables from `.env.production` including `DB_HOST`, `JWT_SECRET`, `CORS_ALLOWED_ORIGINS`, `SPRING_PROFILES_ACTIVE=prod`, `MCP_CLIENT_ENABLED=false`

#### Scenario: Frontend reads backend URL
- **WHEN** frontend container starts
- **THEN** it has `BACKEND_URL=http://backend:8080` for Docker internal network access

### Requirement: Port exposure strategy
The system SHALL only expose nginx ports to the host, keeping other services internal.

#### Scenario: Only nginx ports are public
- **WHEN** docker compose is running
- **THEN** only nginx exposes ports 80 and 443 to the host; backend (8080), frontend (3000), redis (6379), chroma (8000) are only accessible within the Docker network
