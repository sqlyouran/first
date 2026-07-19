## ADDED Requirements

### Requirement: One-click deployment script
The system SHALL provide `scripts/deploy.sh` that automates the full deployment process on the ECS server.

#### Scenario: Deploy script runs all steps
- **WHEN** `scripts/deploy.sh` is executed
- **THEN** it performs: pull latest code → build Docker images → restart services with `docker compose up -d --build`

#### Scenario: Deploy script validates environment
- **WHEN** `scripts/deploy.sh` starts
- **THEN** it checks that `.env.production` exists and required variables are set (DB_HOST, JWT_SECRET, CORS_ALLOWED_ORIGINS, DASHSCOPE_API_KEY)

### Requirement: SSL certificate initialization script
The system SHALL provide `scripts/init-ssl.sh` that sets up Let's Encrypt SSL certificates.

#### Scenario: Init SSL installs certbot and obtains certificate
- **WHEN** `scripts/init-ssl.sh` is executed with a domain name argument
- **THEN** it installs certbot if not present, obtains a certificate for the given domain, and copies certificate files to `nginx/ssl/`

#### Scenario: Certificate renewal command
- **WHEN** the SSL certificate approaches expiration
- **THEN** the script outputs the `certbot renew` command to run for renewal

### Requirement: Production environment file template
The system SHALL document the required `.env.production` file format with all necessary variables.

#### Scenario: Template includes all required variables
- **WHEN** a developer creates `.env.production`
- **THEN** the file includes: `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER`, `DB_PASSWORD`, `DB_USE_SSL`, `JWT_SECRET`, `CORS_ALLOWED_ORIGINS`, `DASHSCOPE_API_KEY`, `SPRING_PROFILES_ACTIVE`, `MCP_CLIENT_ENABLED`, `REDIS_HOST`, `CHROMA_HOST`, `CHROMA_PORT`, `BACKEND_URL`

#### Scenario: JWT secret generation instruction
- **WHEN** a developer needs to generate a production JWT secret
- **THEN** the template includes the command `openssl rand -base64 48` to generate a random secret
