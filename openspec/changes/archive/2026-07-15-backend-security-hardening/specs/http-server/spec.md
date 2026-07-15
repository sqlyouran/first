## ADDED Requirements

### Requirement: 搜索接口输入校验

`SearchController` 的 `GET /api/search` 和 `GET /api/search/suggest` 接口的 `q` 参数 SHALL 添加 `@NotBlank` + `@Size(max=200)` 校验。

#### Scenario: 空搜索词被拒绝

- **WHEN** 请求 `GET /api/search?q=`
- **THEN** HTTP 422，响应 `error_code: "validation_error"`

#### Scenario: 超长搜索词被拒绝

- **WHEN** 请求 `GET /api/search?q=<201个字符>`
- **THEN** HTTP 422，响应 `error_code: "validation_error"`

#### Scenario: 正常搜索词通过

- **WHEN** 请求 `GET /api/search?q=杭州景点`
- **THEN** HTTP 200，正常返回搜索结果
