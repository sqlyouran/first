## ADDED Requirements

### Requirement: Tailwind CSS Utility Classes SHALL be Applied to Rendered DOM

The frontend project SHALL integrate Tailwind CSS 4 such that utility class names declared in JSX are recognized by the build pipeline and applied as real CSS rules in the rendered DOM.

#### Scenario: Tailwind utility produces visible style

- **WHEN** a component uses `className="bg-red-500 p-4"` and the page is opened in a browser
- **THEN** the rendered element's computed `background-color` is `rgb(239, 68, 68)`
- **AND** its computed `padding` is `1rem`

#### Scenario: Build output excludes unused utilities

- **WHEN** the project is built via `npm run build`
- **THEN** the produced CSS bundle contains only utility classes referenced by source files under `app/**` and `components/**`
- **AND** no PostCSS / Tailwind warnings are emitted

### Requirement: shadcn/ui Components SHALL be Available for Use Under `@/components/ui`

The frontend project SHALL initialize shadcn/ui with the `new-york` style and `slate` base color in CSS-variables mode, and SHALL pre-install the `button`, `card`, and `input` components into `components/ui/`.

#### Scenario: Default Button renders with shadcn token classes

- **WHEN** a test renders `<Button>x</Button>` imported from `@/components/ui/button`
- **THEN** the produced element is a `<button>`
- **AND** its `className` contains the tokens `inline-flex`, `items-center`, and `justify-center`

#### Scenario: Outline variant adds border token

- **WHEN** a test renders `<Button variant="outline">x</Button>`
- **THEN** the produced element's `className` contains `border`

#### Scenario: Only the three pre-installed components are present

- **WHEN** the directory `frontend/components/ui/` is listed
- **THEN** exactly three component files are present: `button.tsx`, `card.tsx`, `input.tsx`

### Requirement: lucide-react Icons SHALL Render as Accessible SVGs

The frontend project SHALL include `lucide-react` as a runtime dependency, and icons imported from it SHALL render as inline SVG elements that are hidden from assistive technologies by default.

#### Scenario: Icon renders as decorative SVG

- **WHEN** a test renders `<Sparkles className="h-4 w-4" data-testid="ic" />`
- **THEN** the produced element is an `<svg>` tag
- **AND** its `aria-hidden` attribute equals `"true"`
- **AND** its `className` contains `h-4` and `w-4`

### Requirement: The `cn` Utility SHALL Merge Tailwind Class Lists Without Conflicts

The frontend project SHALL expose a `cn(...inputs: ClassValue[]): string` helper from `@/lib/utils`, backed by `clsx` and `tailwind-merge`, that concatenates class strings while letting later utility classes override conflicting earlier ones.

#### Scenario: Concatenates non-conflicting classes

- **WHEN** code calls `cn('a', 'b')`
- **THEN** the return value is `'a b'`

#### Scenario: Later padding token overrides earlier conflicting token

- **WHEN** code calls `cn('p-2', 'p-4')`
- **THEN** the return value is `'p-4'`

### Requirement: Path Alias `@/*` SHALL Resolve to the Frontend Project Root

The frontend project SHALL maintain the Next.js scaffolded TypeScript path alias `@/*` such that imports of `@/components/ui/*`, `@/lib/utils`, and `@/components` resolve under both the test runner and the production build.

#### Scenario: Type checker accepts alias import

- **WHEN** a source file declares `import { Button } from '@/components/ui/button'`
- **THEN** `npm run build` completes without TypeScript errors

#### Scenario: Test runner accepts alias import

- **WHEN** a test file imports `cn` via `import { cn } from '@/lib/utils'`
- **THEN** the test runner resolves the module without configuration overrides

### Requirement: BFF Boundary SHALL Remain Intact After the Styling Stack is Introduced

The frontend project SHALL NOT introduce any Route Handler or Server Action as part of this change, and the `lib/backend.ts` server-only guard SHALL remain in place.

#### Scenario: No Route Handlers exist under app/

- **WHEN** the command `find frontend/app -name 'route.ts' -o -name 'route.tsx'` is run
- **THEN** the command produces no output

#### Scenario: server-only guard preserved

- **WHEN** the first line of `frontend/lib/backend.ts` is read
- **THEN** the line content is exactly `import "server-only";`

### Requirement: Governance Documents SHALL be Updated to Match the New Styling Stack

The repository's governance documents SHALL be updated to reflect that Tailwind CSS, shadcn/ui, and lucide-react are now part of the locked technology stack, and that other CSS frameworks remain forbidden.

#### Scenario: AGENTS.md no longer forbids Tailwind / shadcn

- **WHEN** the parent repository's `AGENTS.md` is searched for the text "❌ 引入 Tailwind"
- **THEN** no match is returned

#### Scenario: AGENTS.md locks the new styling stack

- **WHEN** the parent repository's `AGENTS.md` "锁定栈" table is read
- **THEN** it contains a row whose name is "样式" and whose value names "Tailwind CSS 4", "shadcn/ui", and "lucide-react"

#### Scenario: project.md tech-stack index lists the styling stack

- **WHEN** `openspec/project.md` "技术栈" section is read
- **THEN** it contains a line that names Tailwind CSS 4, shadcn/ui, and lucide-react

### Requirement: Existing Test Suite SHALL Remain Green

The introduction of the styling stack SHALL NOT break any pre-existing test in the frontend project.

#### Scenario: HelloMessage test still passes

- **WHEN** the command `npm test` is executed in `frontend/`
- **THEN** the existing `HelloMessage.test.tsx` test reports as passing
- **AND** the newly added `components/ui/__tests__/button.test.tsx` test reports as passing
