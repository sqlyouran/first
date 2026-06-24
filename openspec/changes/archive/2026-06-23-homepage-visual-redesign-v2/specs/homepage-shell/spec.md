## MODIFIED Requirements

### Requirement: 首页 Region 挂载契约
`app/page.tsx` SHALL 挂载以下全部 6 个 Region Slot，并按序排列：HeroSlot、FeatureNavSlot、CityGridSlot、HotPostsSlot、HotSpotsSlot、AiLauncherSlot。

#### Scenario: AiLauncherSlot 存在于首页
- **WHEN** 用户访问首页（`/`）
- **THEN** 页面中存在 `data-region="ai-launcher"` 的元素

#### Scenario: 所有 6 个 Region 按序渲染
- **WHEN** 首页渲染完成
- **THEN** DOM 中依次出现 hero、feature-nav、city-grid、hot-posts、hot-spots、ai-launcher 六个 data-region 元素
