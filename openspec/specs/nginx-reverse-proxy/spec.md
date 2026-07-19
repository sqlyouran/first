# nginx-reverse-proxy Specification

## Purpose
TBD - created by archiving change production-deployment. Update Purpose after archive.
## Requirements
### Requirement: Nginx SSL termination
The system SHALL configure Nginx to terminate HTTPS connections and redirect HTTP to HTTPS.

#### Scenario: HTTP redirects to HTTPS
- **WHEN** a user accesses `http://域名`
- **THEN** Nginx returns a 301 redirect to `https://域名`

#### Scenario: HTTPS serves content
- **WHEN** a user accesses `https://域名`
- **THEN** Nginx terminates SSL using certificates from `/etc/nginx/ssl/` and proxies to the appropriate backend service

### Requirement: Route-based request splitting
The system SHALL configure Nginx to split requests by URL path to different upstream services.

#### Scenario: API requests go to backend
- **WHEN** the request path matches `/api/*`
- **THEN** Nginx proxies to `http://backend:8080` preserving the original path and headers

#### Scenario: Non-API requests go to frontend
- **WHEN** the request path does not match `/api/*`
- **THEN** Nginx proxies to `http://frontend:3000` preserving the original path and headers

### Requirement: Proxy headers for correct backend behavior
The system SHALL configure Nginx to pass necessary proxy headers to backend services.

#### Scenario: Backend receives real client IP and protocol
- **WHEN** Nginx proxies a request to backend
- **THEN** it sets `X-Real-IP`, `X-Forwarded-For`, `X-Forwarded-Proto`, and `Host` headers so Spring Boot's `ForwardedHeaderFilter` can determine the real client address and HTTPS status

#### Scenario: WebSocket support for Next.js HMR
- **WHEN** Nginx proxies requests to frontend
- **THEN** it includes `Upgrade` and `Connection` headers to support WebSocket connections (for development HMR; harmless in production)

### Requirement: Nginx configuration files
The system SHALL provide Nginx configuration in two files.

#### Scenario: Main config and site config separation
- **WHEN** the nginx container starts
- **THEN** it uses `nginx/nginx.conf` for worker processes, logging, and global settings, and `nginx/conf.d/default.conf` for server blocks and location rules

