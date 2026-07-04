# homepage-hero — HeroSlot 搜索框功能激活

## MODIFIED Requirements

### Requirement: Hero 容器必须渲染全幅风景摄影 + 大标题 + 搜索框（homepage-visual-v1 新增）

`HeroSlot` SHALL render a full-width section with a background image (picsum.photos placeholder), gradient overlay for text readability, a large display heading (Inter 48px+), subtitle, and a functional search component (`SearchSuggest`). The search component SHALL accept user input, display real-time suggestions, and support form submission to navigate to the search results page. The section MUST use `bg-cover` and `bg-center` classes for the background image.

#### Scenario: Hero 为全幅 section 含背景图

- **WHEN** RTL 渲染 `<HeroSlot />`
- **THEN** `container.querySelector('[data-region="hero"]')` 非 null
- **AND** 该 section 的 className 含 `bg-cover` 或 `bg-[url(...)]`
- **AND** section 高度 ≥ 500px（className 含 `h-[...]`）

#### Scenario: Hero 渲染 h1 标题

- **WHEN** RTL 渲染 `<HeroSlot />`
- **THEN** `container.querySelector('h1')` 非 null
- **AND** h1 的 className 含 `text-5xl` 或 `text-6xl`（48px+ 字号）
- **AND** h1 的 textContent 非空

#### Scenario: Hero 渲染功能性搜索组件

- **WHEN** RTL 渲染 `<HeroSlot />`
- **THEN** `container.querySelector('input[type="text"]')` 非 null
- **AND** input 的 placeholder 属性非空
- **AND** input 旁有 `<button>` 含搜索图标（lucide-react Search）
- **AND** 搜索框被 `<form>` 或等效元素包裹（支持 Enter 提交）

#### Scenario: Hero 搜索框不直接 import fetch 或 lib/backend

- **WHEN** `grep -E "fetchFromBackend|fetch\\(|import.*lib/backend" frontend/app/regions/HeroSlot.tsx`
- **THEN** 输出为空（HeroSlot.tsx 本身不含网络调用）

---

### Requirement: CTA 占位锚点必须为严格 `#`

The hero CTA's placeholder link target SHALL be exactly the string `"#"`.

#### Scenario: ctaHref 严格等于 `#`

- **GIVEN** `hero.data.ts` 已 import
- **WHEN** 读取 default export 的 `ctaHref` 字段
- **THEN** 值 `=== "#"`
