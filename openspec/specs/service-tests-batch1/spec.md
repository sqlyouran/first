## ADDED Requirements

### Requirement: TokenBlacklistService manages token blacklist

TokenBlacklistService SHALL maintain an in-memory set of blacklisted JTIs. `add(jti)` adds to the set, `isBlacklisted(jti)` checks membership.

#### Scenario: Empty blacklist returns false

- **WHEN** `isBlacklisted` is called on a new service with any jti
- **THEN** returns `false`

#### Scenario: Add then check returns true

- **WHEN** `add("jti-123")` is called followed by `isBlacklisted("jti-123")`
- **THEN** returns `true`

#### Scenario: Unadded jti returns false

- **WHEN** `add("jti-A")` then `isBlacklisted("jti-B")`
- **THEN** returns `false`

#### Scenario: Add is idempotent

- **WHEN** `add("jti-X")` is called twice
- **THEN** no exception and `isBlacklisted("jti-X")` returns `true`

#### Scenario: Multiple jtis independent

- **WHEN** `add("jti-1")` and `add("jti-2")`
- **THEN** both `isBlacklisted("jti-1")` and `isBlacklisted("jti-2")` return `true`

---

### Requirement: VerificationCodeStore stores codes with expiration

VerificationCodeStore SHALL store verification codes in memory with TTL-based expiration. Email keys are case-insensitive.

#### Scenario: Save and retrieve code

- **WHEN** `save("test@example.com", "123456", 600)` then `getCode("test@example.com")`
- **THEN** returns `Optional.of("123456")`

#### Scenario: Email is case-insensitive

- **WHEN** `save("Test@X.com", "111111", 600)` then `getCode("test@x.com")`
- **THEN** returns `Optional.of("111111")`

#### Scenario: Unsaved email returns empty

- **WHEN** `getCode("nonexistent@test.com")` without prior save
- **THEN** returns `Optional.empty()`

#### Scenario: Expired code returns empty

- **WHEN** `save("test@test.com", "999999", 0)` then `getCode("test@test.com")`
- **THEN** returns `Optional.empty()`

#### Scenario: Expired code isExpired returns true

- **WHEN** `save("test@test.com", "888888", 0)` then `isExpired("test@test.com")`
- **THEN** returns `true`

#### Scenario: Valid code isExpired returns false

- **WHEN** `save("test@test.com", "777777", 600)` then `isExpired("test@test.com")`
- **THEN** returns `false`

#### Scenario: Nonexistent email isExpired returns true

- **WHEN** `isExpired("never-saved@test.com")`
- **THEN** returns `true`

#### Scenario: Remove deletes code

- **WHEN** `save("test@test.com", "666666", 600)` then `remove("test@test.com")` then `getCode("test@test.com")`
- **THEN** returns `Optional.empty()`

#### Scenario: Remove nonexistent key does not throw

- **WHEN** `remove("nonexistent@test.com")`
- **THEN** no exception is thrown

#### Scenario: Save overwrites previous value

- **WHEN** `save("test@test.com", "111111", 600)` then `save("test@test.com", "222222", 600)` then `getCode("test@test.com")`
- **THEN** returns `Optional.of("222222")`

---

### Requirement: AuthService manages authentication lifecycle

AuthService SHALL handle sendCode, register, login, refresh, logout, getMe, and deleteMe with proper validation, rate limiting, and account locking.

#### Scenario: sendCode saves verification code

- **WHEN** `sendCode("test@example.com", "1.2.3.4")` with no rate limits
- **THEN** `verificationCodeStore.getCode("test@example.com")` returns a 6-digit code

#### Scenario: sendCode IP rate limited throws 429

- **WHEN** `rateLimitService.isSendCodeIpRateLimited("1.2.3.4")` returns `true`
- **THEN** throws `AuthException` with status 429 and error_code `rate_limited`

#### Scenario: sendCode email rate limited returns silently

- **WHEN** IP not limited but `isSendCodeEmailRateLimited` returns `true`
- **THEN** no exception, no code saved

#### Scenario: register creates user successfully

- **WHEN** valid code, email not registered, IP not limited
- **THEN** user created with state `active`, code removed from store

#### Scenario: register IP rate limited throws 429

- **WHEN** `isRegisterRateLimited("1.2.3.4")` returns `true`
- **THEN** throws `AuthException` with `rate_limited`

#### Scenario: register invalid code throws error

- **WHEN** `getCode` returns `Optional.empty()` and `isExpired` returns `false`
- **THEN** throws `AuthException` with `invalid_code`

#### Scenario: register expired code throws error

- **WHEN** `getCode` returns `Optional.empty()` and `isExpired` returns `true`
- **THEN** throws `AuthException` with `expired_code`

#### Scenario: register wrong code throws error

- **WHEN** stored code is "123456" but submitted code is "654321"
- **THEN** throws `AuthException` with `invalid_code`

#### Scenario: register email already exists throws 409

- **WHEN** `existsByEmail` returns `true`
- **THEN** throws `AuthException` with `email_already_registered`

#### Scenario: login successful returns tokens

- **WHEN** valid email/password, user active, not rate limited
- **THEN** returns `LoginResult` with access and refresh tokens

#### Scenario: login IP rate limited throws 429

- **WHEN** `isLoginRateLimited` returns `true`
- **THEN** throws `AuthException` with `rate_limited`

#### Scenario: login nonexistent email throws error

- **WHEN** `findByEmail` returns `Optional.empty()`
- **THEN** throws `AuthException` with `invalid_credentials`

#### Scenario: login deleted user throws error

- **WHEN** user state is `deleted`
- **THEN** throws `AuthException` with `invalid_credentials`

#### Scenario: login locked user not expired throws error

- **WHEN** user state is `locked` and `lockedUntil` is in the future
- **THEN** throws `AuthException` with `account_locked`

#### Scenario: login locked user expired unlocks account

- **WHEN** user state is `locked` and `lockedUntil` is in the past
- **THEN** user state becomes `active`, `failedAttempts` reset to 0

#### Scenario: login email_unverified throws 403

- **WHEN** user state is `email_unverified`
- **THEN** throws `AuthException` with `email_unverified`

#### Scenario: login wrong password increments failed attempts

- **WHEN** password does not match
- **THEN** `failedAttempts` incremented by 1, throws `invalid_credentials`

#### Scenario: login 5th wrong password locks account

- **WHEN** `failedAttempts` becomes 5 after wrong password
- **THEN** user state becomes `locked`, `lockedUntil` set to now + 30 minutes

#### Scenario: login correct password resets failed attempts

- **WHEN** password matches and `failedAttempts > 0`
- **THEN** `failedAttempts` reset to 0

#### Scenario: refresh returns new access token

- **WHEN** valid refresh token, jti not blacklisted, user exists
- **THEN** returns `RefreshResult` with new access token

#### Scenario: refresh blacklisted jti throws error

- **WHEN** `isBlacklisted(jti)` returns `true`
- **THEN** throws `AuthException` with `invalid_refresh_token`

#### Scenario: logout adds jti to blacklist

- **WHEN** valid refresh token with jti
- **THEN** `tokenBlacklistService.add(jti)` is called

---

### Requirement: VoteService manages post voting with notifications

VoteService SHALL handle UP/DOWN votes with toggle behavior and notification side effects.

#### Scenario: Vote UP creates vote and sends notification

- **WHEN** no existing vote, vote type is "up"
- **THEN** vote created with type UP, notification created for post author

#### Scenario: Vote DOWN creates vote without notification

- **WHEN** no existing vote, vote type is "down"
- **THEN** vote created with type DOWN, no notification created

#### Scenario: Same vote type cancels vote

- **WHEN** existing UP vote, new vote is "up"
- **THEN** vote deleted, notification deleted for UP

#### Scenario: Same DOWN vote cancels without notification

- **WHEN** existing DOWN vote, new vote is "down"
- **THEN** vote deleted, no notification action

#### Scenario: Switch UP to DOWN deletes notification

- **WHEN** existing UP vote, new vote is "down"
- **THEN** vote type changed to DOWN, notification deleted

#### Scenario: Switch DOWN to UP creates notification

- **WHEN** existing DOWN vote, new vote is "up"
- **THEN** vote type changed to UP, notification created

#### Scenario: Invalid vote type throws error

- **WHEN** vote type string is "invalid"
- **THEN** throws `PostException` with `validation_error`

#### Scenario: Post not found throws error

- **WHEN** `findByIdAndDeletedFalse` returns `Optional.empty()`
- **THEN** throws `PostException` with `not_found`

#### Scenario: removeVote deletes existing vote

- **WHEN** vote exists for post and user
- **THEN** vote is deleted

#### Scenario: removeVote no vote does nothing

- **WHEN** no vote exists
- **THEN** no exception, no delete called

#### Scenario: getVoteStats returns counts and user vote

- **WHEN** user has voted UP on a post with 3 UP and 1 DOWN
- **THEN** returns upCount=3, downCount=1, userVote="up"

#### Scenario: getVoteStats unauthenticated returns null userVote

- **WHEN** `optionalUserId` is empty
- **THEN** returns counts but `userVote` is null

---

### Requirement: PostService manages post CRUD with pagination

PostService SHALL handle post creation, update, delete, retrieval by ID/slug, and list with 3 sort modes and cursor pagination.

#### Scenario: createPost generates slug from title

- **WHEN** `createPost` with title "My Test Post"
- **THEN** saved post has slug containing "my-test-post" and ID suffix

#### Scenario: createPost user not found throws error

- **WHEN** `existsById(authorId)` returns `false`
- **THEN** throws `PostException` with `not_found`

#### Scenario: createPost invalid status throws error

- **WHEN** status is "invalid_status"
- **THEN** throws `PostException` with `validation_error`

#### Scenario: updatePost by author updates fields

- **WHEN** author matches, request has non-null title
- **THEN** post title is updated

#### Scenario: updatePost non-author throws forbidden

- **WHEN** authorId does not match post's author
- **THEN** throws `PostException` with `access_denied`

#### Scenario: updatePost not found throws error

- **WHEN** `findByIdAndDeletedFalse` returns `Optional.empty()`
- **THEN** throws `PostException` with `not_found`

#### Scenario: deletePost by author marks deleted

- **WHEN** author matches
- **THEN** post `deleted` flag set to `true`

#### Scenario: deletePost non-author throws forbidden

- **WHEN** authorId does not match
- **THEN** throws `PostException` with `access_denied`

#### Scenario: getPost by UUID returns published post

- **WHEN** valid UUID, post status is PUBLISHED
- **THEN** returns post with stats

#### Scenario: getPost by slug returns published post

- **WHEN** valid slug, post status is PUBLISHED
- **THEN** returns post with stats

#### Scenario: getPost non-published throws not found

- **WHEN** post status is DRAFT
- **THEN** throws `PostException` with `not_found`

#### Scenario: getPost not found throws error

- **WHEN** neither UUID nor slug matches
- **THEN** throws `PostException` with `not_found`

#### Scenario: listPosts first load returns cursor

- **WHEN** no cursor provided, offset mode
- **THEN** returns posts with `nextCursor` and `hasMore`

#### Scenario: listPosts cursor mode paginates

- **WHEN** cursor provided
- **THEN** returns next page using cursor

#### Scenario: listPosts size capped at 100

- **WHEN** size > 100
- **THEN** effective size is 100

#### Scenario: listUserPosts filters by author

- **WHEN** `listUserPosts(authorId, ...)`
- **THEN** only posts by that author returned

#### Scenario: Slug special characters cleaned

- **WHEN** title is "Hello!@#$ World"
- **THEN** slug contains "hello-world"

#### Scenario: Slug long title truncated

- **WHEN** title is 100 characters long
- **THEN** slug title part is ≤50 characters + ID suffix

#### Scenario: batchFetchStats empty list returns empty map

- **WHEN** `postIds` is empty
- **THEN** returns empty map

#### Scenario: createPost null tags defaults to empty list

- **WHEN** `request.tags()` is null
- **THEN** post tags is empty list, not null
