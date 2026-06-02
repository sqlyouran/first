# Tasks: 首页视觉层 v1（homepage-visual-v1）

> 严格遵守 RED → GREEN → REFACTOR。每条 `[ ]` 原则上对应一次提交。
> `frontend/` 是独立子仓，所有 `git add/commit/push` 在子仓内执行；父仓最后只追加 submodule 指针 + 同步治理文档。
> 后端 `backend/` 本变更**完全不动**。
> 本变更是"一次性视觉升级"：archive 时 7 份 MODIFIED spec 同步合入主 spec。

## 0. 前置检查

- [ ] 0.1 确认前序 8 个 change 已在 `openspec/changes/archive/` 下（homepage-shell / hero / feature-nav / city-grid / hot-posts / hot-spots / ai-launcher / frontend-styling-stack）
- [ ] 0.2 `openspec/project.md` 已填写 Wanderchina 产品愿景（commit 23977e8）
- [ ] 0.3 父仓与子仓 `git status` 干净，main 分支已合入前序变更
- [ ] 0.4 父仓建工作分支 `change/homepage-visual-v1`
- [ ] 0.5 子仓建对应分支 `change/homepage-visual-v1`
- [ ] 0.6 Node ≥ 20.19

## 1. 子仓 — 基础设施准备

### 1a. shadcn 组件安装
- [ ] 1a.1 `npx shadcn@latest add dialog sheet carousel badge`（4 个组件一次性安装）
- [ ] 1a.2 验证 `frontend/components/ui/` 下新增 `dialog.tsx` / `sheet.tsx` / `carousel.tsx` / `badge.tsx`
- [ ] 1a.3 `npm test` 全绿（安装不改业务代码）
- [ ] 1a.4 子仓提交：`feat(homepage-visual-v1): add shadcn dialog/sheet/carousel/badge`

### 1b. 字体引入
- [ ] 1b.1 修改 `frontend/app/layout.tsx`：引入 Inter + Plus Jakarta Sans（`next/font/google`），挂到 `<html>` 的 CSS 变量
- [ ] 1b.2 修改 `frontend/app/globals.css`：在 `:root` 追加 `--font-sans` / `--font-display`，body 用 `--font-sans`，h1-h3 用 `--font-display`
- [ ] 1b.3 `npm run build` 通过
- [ ] 1b.4 子仓提交：`feat(homepage-visual-v1): add Inter + Plus Jakarta Sans fonts`

### 1c. 页面级视觉契约（globals.css）
- [ ] 1c.1 修改 `frontend/app/globals.css`：追加页面级视觉契约（大留白 / 靛青主色 / section 间距）
  ```css
  :root {
    --color-primary: #1d4ed8; /* blue-700 */
    --spacing-section: 96px; /* desktop */
    --spacing-section-mobile: 64px; /* mobile */
  }
  
  section[data-region] {
    padding-block: var(--spacing-section-mobile);
  }
  
  @media (min-width: 1024px) {
    section[data-region] {
      padding-block: var(--spacing-section);
    }
  }
  ```
- [ ] 1c.2 `npm run build` 通过
- [ ] 1c.3 子仓提交：`feat(homepage-visual-v1): add page-level visual contract to globals.css`

---

## 2. 子仓 — TDD R1（Hero 视觉升级）

### 2a. RED
- [ ] 2a.1 修改 `frontend/app/regions/HeroSlot.test.tsx`：追加视觉契约断言
  - `renders full-width section with background image`（className 含 `bg-cover` 或 `bg-[url(...)]`）
  - `renders h1 with display font and 48px+ size`（className 含 `text-5xl` 或 `text-6xl`）
  - `renders search input with placeholder text`（`<input>` 存在且 placeholder 非空）
- [ ] 2a.2 `npm test` 失败位置在 className / input 断言（旧实现无 className）
- [ ] 2a.3 子仓提交：`test(homepage-visual-v1): RED - HeroSlot visual contract`

### 2b. GREEN
- [ ] 2b.1 修改 `frontend/app/regions/hero.data.ts`：扩充 mock 数据
  ```ts
  export type HeroContent = {
    title: string;
    subtitle: string;
    ctaLabel: string;
    ctaHref: string;
    searchPlaceholder: string;
    backgroundImage: string;
  };
  
  const hero: HeroContent = {
    title: "Wander Beyond the Postcard.",
    subtitle: "Discover the China that travel guides miss.",
    ctaLabel: "Start Exploring",
    ctaHref: "#",
    searchPlaceholder: "Where would you like to go?",
    backgroundImage: "https://picsum.photos/1920/1080?random=1",
  };
  
  export default hero;
  ```
- [ ] 2b.2 改写 `frontend/app/regions/HeroSlot.tsx`：全幅摄影 + 渐变叠层 + 大标题 + 搜索框
  ```tsx
  import hero from "./hero.data";
  import { Input } from "@/components/ui/input";
  import { Button } from "@/components/ui/button";
  import { Search } from "lucide-react";
  
  export default function HeroSlot() {
    return (
      <section
        data-region="hero"
        className="relative h-[600px] bg-cover bg-center"
        style={{ backgroundImage: `url(${hero.backgroundImage})` }}
      >
        <div className="absolute inset-0 bg-gradient-to-r from-black/60 to-transparent" />
        <div className="relative z-10 container mx-auto h-full flex flex-col justify-center items-start max-w-4xl">
          <h1 className="text-5xl lg:text-6xl font-bold text-white mb-4">
            {hero.title}
          </h1>
          <p className="text-xl text-white/90 mb-8">{hero.subtitle}</p>
          <div className="flex gap-2 w-full max-w-md">
            <Input
              type="text"
              placeholder={hero.searchPlaceholder}
              className="flex-1 bg-white/90 backdrop-blur"
            />
            <Button size="icon" className="bg-blue-700 hover:bg-blue-800">
              <Search className="h-5 w-5" />
            </Button>
          </div>
        </div>
      </section>
    );
  }
  ```
- [ ] 2b.3 `npm test` 2a 的 3 个用例 GREEN
- [ ] 2b.4 子仓提交：`feat(homepage-visual-v1): GREEN - HeroSlot full-width hero with search`

### 2c. RED 演练
- [ ] 2c.1 临时改 `HeroSlot.tsx` 去掉 `bg-cover` class，验证测试 RED
- [ ] 2c.2 恢复 `HeroSlot.tsx`，`npm test` 全绿
- [ ] 2c.3 子仓提交（如无调整可跳过）

---

## 3. 子仓 — TDD R2（Feature-nav 视觉升级）

### 3a. RED
- [ ] 3a.1 修改 `frontend/app/regions/FeatureNavSlot.test.tsx`：追加视觉契约断言
  - `renders 4 feature chips with icons`（4 个 `<a>` + lucide icon）
  - `chips have hover effect`（className 含 `hover:`）
- [ ] 3a.2 `npm test` 失败位置在图标 / hover 断言
- [ ] 3a.3 子仓提交：`test(homepage-visual-v1): RED - FeatureNavSlot visual contract`

### 3b. GREEN
- [ ] 3b.1 修改 `frontend/app/regions/featureNav.data.ts`：扩充到 4 个入口
  ```ts
  export type FeatureNavItem = {
    label: string;
    href: string;
    icon: string; // lucide-react icon name
  };
  
  const featureNavItems: readonly FeatureNavItem[] = [
    { label: "Cities", href: "#cities", icon: "MapPin" },
    { label: "Stories", href: "#stories", icon: "BookOpen" },
    { label: "Hidden Spots", href: "#spots", icon: "Compass" },
    { label: "Plan with AI", href: "#ai", icon: "Sparkles" },
  ];
  
  export default featureNavItems;
  ```
- [ ] 3b.2 改写 `frontend/app/regions/FeatureNavSlot.tsx`：横向 4 chip + lucide 图标
  ```tsx
  import featureNavItems from "./featureNav.data";
  import { MapPin, BookOpen, Compass, Sparkles } from "lucide-react";
  
  const iconMap = { MapPin, BookOpen, Compass, Sparkles };
  
  export default function FeatureNavSlot() {
    return (
      <section data-region="feature-nav" className="py-12 bg-slate-50">
        <div className="container mx-auto grid grid-cols-2 md:grid-cols-4 gap-4">
          {featureNavItems.map((item) => {
            const Icon = iconMap[item.icon as keyof typeof iconMap];
            return (
              <a
                key={item.label}
                href={item.href}
                className="flex flex-col items-center gap-2 p-6 rounded-lg bg-white shadow-sm hover:shadow-md transition-shadow"
              >
                <Icon className="h-8 w-8 text-blue-700" />
                <span className="font-medium text-slate-900">{item.label}</span>
              </a>
            );
          })}
        </div>
      </section>
    );
  }
  ```
- [ ] 3b.3 `npm test` 3a 的 2 个用例 GREEN
- [ ] 3b.4 子仓提交：`feat(homepage-visual-v1): GREEN - FeatureNavSlot 4 chips with icons`

---

## 4. 子仓 — TDD R3（City-grid 视觉升级 + Mock 数据扩充）

### 4a. RED
- [ ] 4a.1 修改 `frontend/app/regions/CityGridSlot.test.tsx`：追加视觉契约断言
  - `renders 8 city cards`（8 个 `<a>`）
  - `each card has image, title, and badge`（`<img>` + `<h3>` + Badge）
  - `cards use responsive grid (2 cols mobile, 4 cols desktop)`（className 含 `grid-cols-2` 和 `md:grid-cols-4`）
- [ ] 4a.2 `npm test` 失败位置在卡片数量 / Badge 断言
- [ ] 4a.3 子仓提交：`test(homepage-visual-v1): RED - CityGridSlot visual contract`

### 4b. GREEN
- [ ] 4b.1 修改 `frontend/app/regions/cityGrid.data.ts`：扩充到 8 个城市
  ```ts
  export type CityGridItem = {
    label: string; // English name
    labelZh: string; // Chinese name
    href: string;
    image: string;
    description: string;
    bestSeason: string;
  };
  
  const items: readonly CityGridItem[] = [
    { label: "Beijing", labelZh: "北京", href: "#", image: "https://picsum.photos/800/600?random=10", description: "Ancient capital with imperial grandeur", bestSeason: "Autumn" },
    { label: "Shanghai", labelZh: "上海", href: "#", image: "https://picsum.photos/800/600?random=11", description: "Modern metropolis on the Huangpu", bestSeason: "Spring" },
    { label: "Chengdu", labelZh: "成都", href: "#", image: "https://picsum.photos/800/600?random=12", description: "Home of pandas and spicy cuisine", bestSeason: "Spring" },
    { label: "Xi'an", labelZh: "西安", href: "#", image: "https://picsum.photos/800/600?random=13", description: "Terracotta warriors and Silk Road heritage", bestSeason: "Autumn" },
    { label: "Hangzhou", labelZh: "杭州", href: "#", image: "https://picsum.photos/800/600?random=14", description: "West Lake and tea plantations", bestSeason: "Spring" },
    { label: "Guilin", labelZh: "桂林", href: "#", image: "https://picsum.photos/800/600?random=15", description: "Karst mountains and Li River cruises", bestSeason: "Summer" },
    { label: "Lijiang", labelZh: "丽江", href: "#", image: "https://picsum.photos/800/600?random=16", description: "Naxi old town and Jade Dragon Snow Mountain", bestSeason: "Winter" },
    { label: "Xiamen", labelZh: "厦门", href: "#", image: "https://picsum.photos/800/600?random=17", description: "Coastal charm and Gulangyu Island", bestSeason: "Autumn" },
  ];
  
  export default items;
  ```
- [ ] 4b.2 改写 `frontend/app/regions/CityGridSlot.tsx`：4 列卡片 + 季节 Badge
  ```tsx
  import items from "./cityGrid.data";
  import { Card } from "@/components/ui/card";
  import { Badge } from "@/components/ui/badge";
  
  export default function CityGridSlot() {
    return (
      <section data-region="city-grid" className="py-16 lg:py-24">
        <div className="container mx-auto">
          <h2 className="text-3xl lg:text-4xl font-bold text-slate-900 mb-8">
            Explore by City
          </h2>
          <div className="grid grid-cols-2 md:grid-cols-4 gap-6">
            {items.map((item) => (
              <a key={item.label} href={item.href}>
                <Card className="overflow-hidden hover:shadow-lg transition-shadow">
                  <div className="aspect-[4/3] bg-cover bg-center" style={{ backgroundImage: `url(${item.image})` }} />
                  <div className="p-4">
                    <div className="flex items-center justify-between mb-2">
                      <h3 className="text-lg font-semibold text-slate-900">{item.label}</h3>
                      <Badge variant="secondary">{item.bestSeason}</Badge>
                    </div>
                    <p className="text-sm text-slate-500">{item.labelZh}</p>
                    <p className="text-sm text-slate-600 mt-1 line-clamp-2">{item.description}</p>
                  </div>
                </Card>
              </a>
            ))}
          </div>
        </div>
      </section>
    );
  }
  ```
- [ ] 4b.3 `npm test` 4a 的 3 个用例 GREEN
- [ ] 4b.4 子仓提交：`feat(homepage-visual-v1): GREEN - CityGridSlot 8 cities with badges`

---

## 5. 子仓 — TDD R4（Hot-posts 视觉升级 + Mock 数据扩充）

### 5a. RED
- [ ] 5a.1 修改 `frontend/app/regions/HotPostsSlot.test.tsx`：追加视觉契约断言
  - `renders 3 story cards (1 large + 2 small)`（3 个 `<a>`）
  - `large card has image and title`（`<img>` + `<h3>`）
  - `uses storytelling layout (left large, right small stack)`（className 含 `grid-cols-3`）
- [ ] 5a.2 `npm test` 失败位置在布局断言
- [ ] 5a.3 子仓提交：`test(homepage-visual-v1): RED - HotPostsSlot visual contract`

### 5b. GREEN
- [ ] 5b.1 修改 `frontend/app/regions/hotPosts.data.ts`：扩充到 6 篇攻略
  ```ts
  export type HotPostItem = {
    title: string; // English storytelling title
    location: string; // Chinese location
    href: string;
    image: string;
    excerpt: string;
  };
  
  const items: readonly HotPostItem[] = [
    { title: "3-Day Yunnan Hidden Tea Trail", location: "云南", href: "#", image: "https://picsum.photos/800/600?random=20", excerpt: "Discover ancient tea villages beyond the tourist path." },
    { title: "Beijing Hutong Coffee Crawl", location: "北京", href: "#", image: "https://picsum.photos/800/600?random=21", excerpt: "Where tradition meets third-wave coffee culture." },
    { title: "Silk Road Sunrise: Xi'an to Dunhuang", location: "甘肃", href: "#", image: "https://picsum.photos/800/600?random=22", excerpt: "Chasing dawn across 1,500km of desert highway." },
    { title: "Chengdu's Late-Night Food Map", location: "成都", href: "#", image: "https://picsum.photos/800/600?random=23", excerpt: "Hotpot, skewers, and street food after midnight." },
    { title: "Hangzhou's West Lake at Dawn", location: "杭州", href: "#", image: "https://picsum.photos/800/600?random=24", excerpt: "Why 6am is the magic hour for China's most famous lake." },
    { title: "Guilin's Karst by Kayak", location: "桂林", href: "#", image: "https://picsum.photos/800/600?random=25", excerpt: "Paddling the Li River without the tour groups." },
  ];
  
  export default items;
  ```
- [ ] 5b.2 改写 `frontend/app/regions/HotPostsSlot.tsx`：左大右小 storytelling 布局
  ```tsx
  import items from "./hotPosts.data";
  import { Card } from "@/components/ui/card";
  
  export default function HotPostsSlot() {
    const [featured, ...rest] = items.slice(0, 3); // 1 large + 2 small
    
    return (
      <section data-region="hot-posts" className="py-16 lg:py-24 bg-slate-50">
        <div className="container mx-auto">
          <h2 className="text-3xl lg:text-4xl font-bold text-slate-900 mb-8">
            Stories from the Road
          </h2>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            {/* Large featured card */}
            <a href={featured.href} className="md:col-span-2">
              <Card className="overflow-hidden hover:shadow-lg transition-shadow h-full">
                <div className="aspect-[16/9] bg-cover bg-center" style={{ backgroundImage: `url(${featured.image})` }} />
                <div className="p-6">
                  <h3 className="text-2xl font-bold text-slate-900 mb-2">{featured.title}</h3>
                  <p className="text-sm text-slate-500 mb-2">{featured.location}</p>
                  <p className="text-slate-600">{featured.excerpt}</p>
                </div>
              </Card>
            </a>
            {/* Small cards stack */}
            <div className="flex flex-col gap-6">
              {rest.map((item) => (
                <a key={item.title} href={item.href}>
                  <Card className="overflow-hidden hover:shadow-lg transition-shadow">
                    <div className="flex gap-4 p-4">
                      <div className="w-24 h-24 flex-shrink-0 bg-cover bg-center rounded" style={{ backgroundImage: `url(${item.image})` }} />
                      <div>
                        <h3 className="text-lg font-semibold text-slate-900 mb-1">{item.title}</h3>
                        <p className="text-sm text-slate-500">{item.location}</p>
                      </div>
                    </div>
                  </Card>
                </a>
              ))}
            </div>
          </div>
        </div>
      </section>
    );
  }
  ```
- [ ] 5b.3 `npm test` 5a 的 3 个用例 GREEN
- [ ] 5b.4 子仓提交：`feat(homepage-visual-v1): GREEN - HotPostsSlot storytelling layout`

---

## 6. 子仓 — TDD R5（Hot-spots 视觉升级 + Mock 数据扩充）

### 6a. RED
- [ ] 6a.1 修改 `frontend/app/regions/HotSpotsSlot.test.tsx`：追加视觉契约断言
  - `renders carousel with 8 spot cards`（8 个 `<a>`）
  - `each card has image, title, and tags`（`<img>` + `<h3>` + Badge）
  - `carousel has horizontal scroll on mobile`（className 含 `overflow-x-auto` 或 Carousel 组件）
- [ ] 6a.2 `npm test` 失败位置在 Carousel 断言
- [ ] 6a.3 子仓提交：`test(homepage-visual-v1): RED - HotSpotsSlot visual contract`

### 6b. GREEN
- [ ] 6b.1 修改 `frontend/app/regions/hotSpots.data.ts`：扩充到 8 个景点
  ```ts
  export type HotSpotItem = {
    name: string; // English name
    nameZh: string; // Chinese name
    href: string;
    image: string;
    tags: string[];
  };
  
  const items: readonly HotSpotItem[] = [
    { name: "Zhangjiajie Glass Bridge", nameZh: "张家界玻璃桥", href: "#", image: "https://picsum.photos/400/300?random=30", tags: ["Nature", "Thrill"] },
    { name: "Yuanyang Rice Terraces", nameZh: "元阳梯田", href: "#", image: "https://picsum.photos/400/300?random=31", tags: ["Nature", "Photography"] },
    { name: "Dunhuang Mogao Caves", nameZh: "敦煌莫高窟", href: "#", image: "https://picsum.photos/400/300?random=32", tags: ["History", "Art"] },
    { name: "Fenghuang Ancient Town", nameZh: "凤凰古城", href: "#", image: "https://picsum.photos/400/300?random=33", tags: ["Culture", "Architecture"] },
    { name: "Daocheng Yading", nameZh: "稻城亚丁", href: "#", image: "https://picsum.photos/400/300?random=34", tags: ["Nature", "Hiking"] },
    { name: "Pingyao Old Town", nameZh: "平遥古城", href: "#", image: "https://picsum.photos/400/300?random=35", tags: ["History", "Architecture"] },
    { name: "Hukou Waterfall", nameZh: "壶口瀑布", href: "#", image: "https://picsum.photos/400/300?random=36", tags: ["Nature", "Photography"] },
    { name: "Tiger Leaping Gorge", nameZh: "虎跳峡", href: "#", image: "https://picsum.photos/400/300?random=37", tags: ["Nature", "Hiking"] },
  ];
  
  export default items;
  ```
- [ ] 6b.2 改写 `frontend/app/regions/HotSpotsSlot.tsx`：横向 Carousel + 标签
  ```tsx
  import items from "./hotSpots.data";
  import { Card } from "@/components/ui/card";
  import { Badge } from "@/components/ui/badge";
  
  export default function HotSpotsSlot() {
    return (
      <section data-region="hot-spots" className="py-16 lg:py-24">
        <div className="container mx-auto">
          <div className="flex items-center justify-between mb-8">
            <h2 className="text-3xl lg:text-4xl font-bold text-slate-900">
              Off-the-Beaten-Path Spots
            </h2>
            <a href="#all-spots" className="text-blue-700 hover:text-blue-800 font-medium">
              See all →
            </a>
          </div>
          <div className="flex gap-6 overflow-x-auto pb-4 snap-x snap-mandatory md:grid md:grid-cols-4 md:overflow-visible">
            {items.map((item) => (
              <a key={item.name} href={item.href} className="flex-shrink-0 w-64 md:w-auto snap-start">
                <Card className="overflow-hidden hover:shadow-lg transition-shadow">
                  <div className="aspect-[4/3] bg-cover bg-center" style={{ backgroundImage: `url(${item.image})` }} />
                  <div className="p-4">
                    <h3 className="text-lg font-semibold text-slate-900 mb-1">{item.name}</h3>
                    <p className="text-sm text-slate-500 mb-2">{item.nameZh}</p>
                    <div className="flex gap-2">
                      {item.tags.map((tag) => (
                        <Badge key={tag} variant="outline" className="text-xs">
                          {tag}
                        </Badge>
                      ))}
                    </div>
                  </div>
                </Card>
              </a>
            ))}
          </div>
        </div>
      </section>
    );
  }
  ```
- [ ] 6b.3 `npm test` 6a 的 3 个用例 GREEN
- [ ] 6b.4 子仓提交：`feat(homepage-visual-v1): GREEN - HotSpotsSlot carousel with tags`

---

## 7. 子仓 — TDD R6（AI Launcher 视觉升级）

### 7a. RED
- [ ] 7a.1 修改 `frontend/app/regions/AiLauncherSlot.test.tsx`：追加视觉契约断言
  - `renders floating button with Plan with AI text`（`<button>` 文本含 "Plan with AI"）
  - `button opens dialog on desktop`（点击后 Dialog 组件可见）
  - `button opens sheet on mobile`（窗口 < 1024px 时 Sheet 可见）
- [ ] 7a.2 `npm test` 失败位置在 Dialog / Sheet 断言
- [ ] 7a.3 子仓提交：`test(homepage-visual-v1): RED - AiLauncherSlot visual contract`

### 7b. GREEN
- [ ] 7b.1 改写 `frontend/app/regions/AiLauncherSlot.tsx`：浮按钮 + Dialog / Sheet 双形态
  ```tsx
  import { useState } from "react";
  import { Dialog, DialogContent, DialogTrigger } from "@/components/ui/dialog";
  import { Sheet, SheetContent, SheetTrigger } from "@/components/ui/sheet";
  import { Sparkles } from "lucide-react";
  
  export default function AiLauncherSlot() {
    const [open, setOpen] = useState(false);
    
    const triggerButton = (
      <button
        type="button"
        onClick={() => setOpen(true)}
        className="fixed bottom-6 right-6 z-50 flex items-center gap-2 px-6 py-3 bg-blue-700 hover:bg-blue-800 text-white rounded-full shadow-lg transition-all"
      >
        <Sparkles className="h-5 w-5" />
        <span>Plan with AI</span>
      </button>
    );
    
    return (
      <div data-region="ai-launcher">
        {/* Desktop: Dialog */}
        <Dialog open={open} onOpenChange={setOpen}>
          <DialogTrigger asChild>
            <div className="hidden md:block">{triggerButton}</div>
          </DialogTrigger>
          <DialogContent className="sm:max-w-md">
            <div className="p-6 text-center">
              <Sparkles className="h-12 w-12 text-blue-700 mx-auto mb-4" />
              <h3 className="text-xl font-bold text-slate-900 mb-2">AI Trip Planner</h3>
              <p className="text-slate-600">Coming soon. Plan your perfect China itinerary with AI.</p>
            </div>
          </DialogContent>
        </Dialog>
        
        {/* Mobile: Sheet */}
        <Sheet open={open} onOpenChange={setOpen}>
          <SheetTrigger asChild>
            <div className="md:hidden">{triggerButton}</div>
          </SheetTrigger>
          <SheetContent side="bottom">
            <div className="p-6 text-center">
              <Sparkles className="h-12 w-12 text-blue-700 mx-auto mb-4" />
              <h3 className="text-xl font-bold text-slate-900 mb-2">AI Trip Planner</h3>
              <p className="text-slate-600">Coming soon. Plan your perfect China itinerary with AI.</p>
            </div>
          </SheetContent>
        </Sheet>
      </div>
    );
  }
  ```
- [ ] 7b.2 `npm test` 7a 的 3 个用例 GREEN
- [ ] 7b.3 子仓提交：`feat(homepage-visual-v1): GREEN - AiLauncherSlot Dialog/Sheet dual mode`

---

## 8. 子仓 — 构建与回归

- [ ] 8.1 `npm run build` 通过
- [ ] 8.2 `npm test` 全绿（含 6 个 Slot 的视觉契约断言）
- [ ] 8.3 浏览器访问 `http://localhost:3000/`，验证 6 个 region 视觉正确
- [ ] 8.4 响应式测试：浏览器 DevTools 切换 mobile / tablet / desktop，验证布局正确
- [ ] 8.5 `find frontend/app -name 'route.ts' -o -name 'route.tsx'` 输出为空
- [ ] 8.6 `head -1 frontend/lib/backend.ts` 输出 `import "server-only";`
- [ ] 8.7 `git diff main..HEAD -- lib/backend.ts package.json` 输出为空（除 shadcn 新增依赖）
- [ ] 8.8 子仓推送 `change/homepage-visual-v1`

## 9. 父仓追指针 + 治理同步

- [ ] 9.1 父仓 `git add frontend` 追指针
- [ ] 9.2 子仓更新 `frontend/README.md`：在《首页骨架》小节标注"视觉层 v1 已注入"
- [ ] 9.3 父仓提交：`bump: frontend -> <new-sha> (homepage-visual-v1)`
- [ ] 9.4 父仓推送

## 10. 验证清单

- [ ] 10.1 `cd frontend && npm test` 全绿（含 6 个 Slot 视觉契约断言）
- [ ] 10.2 `cd frontend && npm run build` 通过
- [ ] 10.3 `find frontend/app -name 'route.ts' -o -name 'route.tsx'` 输出为空
- [ ] 10.4 `head -1 frontend/lib/backend.ts` 输出 `import "server-only";`
- [ ] 10.5 6 个 Slot 的 `.tsx` 中**未** import `lib/backend` / `fetchFromBackend`
- [ ] 10.6 `frontend/package.json` 仅新增 shadcn 相关依赖（dialog / sheet / carousel / badge）
- [ ] 10.7 父仓 `git diff --stat main..HEAD` 仅含 submodule 指针 + 本 change 4 件套

## 11. 归档（archive 时同步主 specs）

- [ ] 11.1 archive 阶段：把 7 份 MODIFIED spec delta 应用到主 spec（`openspec/specs/homepage-shell/spec.md` + 6 个 capability spec）
- [ ] 11.2 移动 change 目录到 `openspec/changes/archive/<YYYY-MM-DD>-homepage-visual-v1/`
- [ ] 11.3 父仓提交归档：`chore(openspec): archive homepage-visual-v1`
- [ ] 11.4 archive 后核查：`openspec/specs/` 下 7 份主 spec 均含视觉契约 Requirement

## 12. 后续（不在本变更范围）

- [ ] 真实数据接入（后端 API）
- [ ] 暗色模式切换 UI（`next-themes` 集成）
- [ ] 真实图片素材（unsplash / 自研）
- [ ] 微交互 / 动效（fade / slide / scroll reveal）
- [ ] SEO meta / OG 图 / 性能预算

---

> **里程碑**：本变更归档后，Wanderchina 首页具备"能给人看"的产品形态，6 个 region 的视觉契约统一，后续每个 region 进入下一阶段（接入真实数据 / 微交互 / 性能优化），按各自独立 propose 推进。
