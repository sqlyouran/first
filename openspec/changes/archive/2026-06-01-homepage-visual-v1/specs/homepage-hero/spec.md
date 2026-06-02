## MODIFIED Requirements

### Requirement: Hero 容器必须渲染全幅风景摄影 + 大标题 + 搜索框

`HeroSlot` SHALL render a full-width section with a background image (picsum.photos placeholder), gradient overlay for text readability, a large display heading (Inter 48px+), subtitle, and a search input with icon button. The section MUST use `bg-cover` and `bg-center` classes for the background image.

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

#### Scenario: Hero 渲染搜索输入框

- **WHEN** RTL 渲染 `<HeroSlot />`
- **THEN** `container.querySelector('input[type="text"]')` 非 null
- **AND** input 的 placeholder 属性非空
- **AND** input 旁有 `<button>` 含搜索图标（lucide-react Search）

---

### Requirement: Hero 数据来源必须包含背景图 URL 和搜索占位文本

The hero content SHALL be sourced from `frontend/app/regions/hero.data.ts` with expanded fields: `title`, `subtitle`, `ctaLabel`, `ctaHref`, `searchPlaceholder`, and `backgroundImage`. The `backgroundImage` MUST be a valid URL (picsum.photos placeholder).

#### Scenario: data 文件包含背景图 URL

- **WHEN** 静态 import `hero.data.ts` 的 default export
- **THEN** `backgroundImage` 字段为非空字符串
- **AND** `backgroundImage` 以 `http://` 或 `https://` 开头

#### Scenario: data 文件包含搜索占位文本

- **WHEN** 静态 import `hero.data.ts` 的 default export
- **THEN** `searchPlaceholder` 字段为非空字符串
- **AND** `searchPlaceholder.trim().length > 0`
