## 1. 测试脚手架

- [x] 1.1 创建 `backend/src/test/java/com/mooc/app/service/JwtServiceTest.java`，配置测试常量和辅助方法（createTestUser、createJwtService）

## 2. 构造器测试

- [x] 2.1 `constructor_validSecret_initializesService` — 合法 secret 构造成功
- [x] 2.2 `constructor_shortSecret_throwsWeakKeyException` — secret 太短抛异常

## 3. generateAccessToken 测试

- [x] 3.1 `generateAccessToken_parseable` — 生成的 token 能被 parseToken 解析
- [x] 3.2 `generateAccessToken_subjectIsUserId` — sub 等于 user.getId()
- [x] 3.3 `generateAccessToken_emailClaimMatches` — email claim 正确
- [x] 3.4 `generateAccessToken_stateClaimMatches` — state claim 正确
- [x] 3.5 `generateAccessToken_expiryIsCorrect` — exp - iat ≈ accessTokenExpiry（±2s）
- [x] 3.6 `generateAccessToken_noJti` — claims.getId() 为 null
- [x] 3.7 `generateAccessToken_differentUsersDifferentTokens` — 不同用户 token 不同

## 4. generateRefreshToken 测试

- [x] 4.1 `generateRefreshToken_parseable` — 生成的 token 能被 parseToken 解析
- [x] 4.2 `generateRefreshToken_subjectIsUserId` — sub 等于 user.getId()
- [x] 4.3 `generateRefreshToken_jtiIsValidUuid` — jti 非空且是合法 UUID
- [x] 4.4 `generateRefreshToken_jtiIsUnique` — 同一用户两次生成 jti 不同
- [x] 4.5 `generateRefreshToken_noEmailOrState` — 不含 email/state
- [x] 4.6 `generateRefreshToken_expiryIsCorrect` — exp - iat ≈ refreshTokenExpiry（±2s）

## 5. parseToken 异常路径测试

- [x] 5.1 `parseToken_wrongSignature_returnsEmpty` — 不同 key 签的 token → empty
- [x] 5.2 `parseToken_expiredToken_returnsEmpty` — 过期 token → empty
- [x] 5.3 `parseToken_malformedString_returnsEmpty` — "not.a.jwt" → empty
- [x] 5.4 `parseToken_null_returnsEmpty` — null → empty
- [x] 5.5 `parseToken_emptyString_returnsEmpty` — "" → empty
- [x] 5.6 `parseToken_tamperedToken_returnsEmpty` — 篡改一个字符 → empty

## 6. Getter 测试

- [x] 6.1 `getAccessTokenExpirySeconds_returnsConfiguredValue`
- [x] 6.2 `getRefreshTokenExpirySeconds_returnsConfiguredValue`

## 7. 验证

- [x] 7.1 运行 `mvn -f backend/pom.xml test -pl . -Dtest=JwtServiceTest` 确保所有测试通过
- [x] 7.2 Code review 自检
