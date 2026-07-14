## ADDED Requirements

### Requirement: Constructor validates secret key length

JwtService SHALL reject secrets shorter than 32 bytes (256 bits) by throwing `io.jsonwebtoken.security.WeakKeyException`. Valid secrets (≥32 bytes) SHALL initialize the service successfully.

#### Scenario: Valid secret initializes service

- **WHEN** JwtService is constructed with a 48-character UTF-8 secret
- **THEN** no exception is thrown and the service is ready for use

#### Scenario: Short secret throws WeakKeyException

- **WHEN** JwtService is constructed with a secret shorter than 32 bytes (e.g. "short")
- **THEN** `WeakKeyException` is thrown

---

### Requirement: Access token contains correct claims

`generateAccessToken(user)` SHALL produce a signed JWT containing `sub` (user ID), `email`, `state`, `iat`, and `exp` claims. It SHALL NOT contain a `jti` claim.

#### Scenario: Access token can be parsed back

- **WHEN** an access token is generated for a test user
- **THEN** `parseToken` returns a non-empty `Optional<Claims>`

#### Scenario: sub equals user ID

- **WHEN** an access token is generated for a user with ID `uuid-abc`
- **THEN** `claims.getSubject()` equals `uuid-abc.toString()`

#### Scenario: email claim matches user email

- **WHEN** an access token is generated for a user with email `test@example.com`
- **THEN** `claims.get("email", String.class)` equals `"test@example.com"`

#### Scenario: state claim matches user state name

- **WHEN** an access token is generated for a user with state `active`
- **THEN** `claims.get("state", String.class)` equals `"active"`

#### Scenario: exp equals iat plus accessTokenExpiry

- **WHEN** an access token is generated with `accessTokenExpiry = 1800`
- **THEN** `exp - iat` is between 1798 and 1802 seconds (±2s tolerance)

#### Scenario: Access token has no jti

- **WHEN** an access token is generated
- **THEN** `claims.getId()` is null

#### Scenario: Different users produce different tokens

- **WHEN** access tokens are generated for two different users
- **THEN** the token strings are not equal

---

### Requirement: Refresh token contains correct claims

`generateRefreshToken(user)` SHALL produce a signed JWT containing `jti` (random UUID), `sub` (user ID), `iat`, and `exp`. It SHALL NOT contain `email` or `state` claims.

#### Scenario: Refresh token can be parsed back

- **WHEN** a refresh token is generated
- **THEN** `parseToken` returns a non-empty `Optional<Claims>`

#### Scenario: sub equals user ID

- **WHEN** a refresh token is generated for a user with ID `uuid-xyz`
- **THEN** `claims.getSubject()` equals `uuid-xyz.toString()`

#### Scenario: jti is a valid non-null UUID

- **WHEN** a refresh token is generated
- **THEN** `claims.getId()` is non-null and can be parsed by `UUID.fromString`

#### Scenario: Each refresh token has a unique jti

- **WHEN** two refresh tokens are generated for the same user
- **THEN** their `jti` values are different

#### Scenario: Refresh token has no email or state

- **WHEN** a refresh token is generated
- **THEN** `claims.get("email")` is null AND `claims.get("state")` is null

#### Scenario: exp uses refreshTokenExpiry

- **WHEN** a refresh token is generated with `refreshTokenExpiry = 604800`
- **THEN** `exp - iat` is between 604798 and 604802 seconds (±2s tolerance)

---

### Requirement: parseToken rejects invalid tokens

`parseToken` SHALL return `Optional.empty()` for any invalid input without throwing an exception. Invalid inputs include: wrong-signature tokens, expired tokens, malformed strings, null, empty strings, and tampered tokens.

#### Scenario: Wrong signature returns empty

- **WHEN** a token signed with key-A is parsed by a JwtService initialized with key-B
- **THEN** `parseToken` returns `Optional.empty()`

#### Scenario: Expired token returns empty

- **WHEN** a token generated with `expiry = 0` (immediately expired) is parsed
- **THEN** `parseToken` returns `Optional.empty()`

#### Scenario: Malformed string returns empty

- **WHEN** `parseToken` is called with `"not.a.jwt"`
- **THEN** it returns `Optional.empty()`

#### Scenario: Null input returns empty

- **WHEN** `parseToken` is called with `null`
- **THEN** it returns `Optional.empty()`

#### Scenario: Empty string returns empty

- **WHEN** `parseToken` is called with `""`
- **THEN** it returns `Optional.empty()`

#### Scenario: Tampered token returns empty

- **WHEN** a valid token has one character altered in the payload
- **THEN** `parseToken` returns `Optional.empty()`

---

### Requirement: Getter methods return configured values

`getAccessTokenExpirySeconds()` and `getRefreshTokenExpirySeconds()` SHALL return the exact values passed to the constructor.

#### Scenario: getAccessTokenExpirySeconds returns constructor value

- **WHEN** JwtService is constructed with `accessTokenExpiry = 1800`
- **THEN** `getAccessTokenExpirySeconds()` returns `1800`

#### Scenario: getRefreshTokenExpirySeconds returns constructor value

- **WHEN** JwtService is constructed with `refreshTokenExpiry = 604800`
- **THEN** `getRefreshTokenExpirySeconds()` returns `604800`
