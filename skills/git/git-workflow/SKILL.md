---
name: git-workflow
description: Git 工作流規範。當建立 Issue、分支、PR、執行 merge 或規劃整體開發流程時使用。
---

# Git 工作流規範

## 何時使用此 Skill

當你需要：建立 Issue / 分支 / PR、決定 merge 策略、或規劃從 issue 到 release 的完整流程時。

## 0. 完整開發流程

```
Issue (#N) ──► branch <type>/<short-desc> ──► commits ──► PR ──► squash-merge to main ──┐
                                                                                         │
                                          ┌──────────────────────────────────────────────┘
                                          ▼
                  累積變更（on main）──► version bump ──► tag vX.Y.Z ──► push --follow-tags ──► GitHub Release
```

階段對應規範：Issue / branch / PR / merge → 本 skill；commit 訊息 → [`../conventional-commits/SKILL.md`](../conventional-commits/SKILL.md)；版本 bump / tag / CHANGELOG / GitHub Release → [`../release-management/SKILL.md`](../release-management/SKILL.md)（含 bump-on-main 紀律與 release-train 節奏）。

## 1. 分支命名規範

格式：`<type>/<short-description>`，可選帶 issue：`<type>/<issue>-<short-description>`

| 類型 | 範例 |
|------|------|
| `feat/` | `feat/user-auth`、`feat/123-user-auth` |
| `fix/` | `fix/login-timeout` |
| `docs/` | `docs/api-guide` |
| `refactor/` | `refactor/db-layer` |
| `hotfix/` | `hotfix/security-patch` |

> 本工作流採 trunk-based，**不使用 `release/` 分支**：版本 bump 與 tag 一律在 `main` 上完成（見 [`../release-management/SKILL.md`](../release-management/SKILL.md) §2）。`hotfix/` 為 main 上緊急修補用，merge 後同樣在 main bump。Merge 策略於每次 merge 時詢問使用者（見 §5）。

| 規則 | Why |
|------|-----|
| 全部小寫、`-` 分隔 | Windows/macOS 大小寫敏感性不一致；底線在終端機選取時容易誤判 |
| 簡潔 (2-4 字) | 終端機列表截斷時仍可辨識 |
| 不用個人名 (`feat/jason-fix`) | 分支應描述「做什麼」非「誰做」；個人名讓非當事人難以接手、PR 移交時也需改名 |

> 分支前綴採用與 commit `type` 對齊（`feat/`、`fix/`、`docs/`、`refactor/`），讓 issue / branch / commit / PR 整條動線視覺一致。

## 2. Issue 撰寫規範

### 標題

祈使句、描述性、< 70 字元。範例：`Login times out under high latency`、`Support OAuth login`。

可選：用 commit type 前綴（`feat: ...`、`fix: ...`）讓 issue / branch / commit / PR 視覺對齊；本專案採此風格時，整條動線一致即可，不採用時靠 label / milestone 分類也是主流做法。

> 語言一致、避免 emoji 等跨 skill 風格規範見父層 [`../SKILL.md` §跨 skill 風格規範](../SKILL.md)。

### 內文模板（建議）

```markdown
## Problem
<為什麼這是個問題；現狀帶來什麼影響>

## Expected
<期望達成的結果；對外契約>

## Definition of Done
- [ ] <可驗證的完工條件 1>
- [ ] <可驗證的完工條件 2>
```

> 內文**只寫永遠為真的事實**，不嵌入分支名 / SHA / 「awaiting PR」「[WIP]」等 status 字句（rationale 與反例見 §4）。

### Body vs Comments 分工

Issue 內容依時效性分三層落腳，對齊 Jira / Linear 的 Description / Comments / Status 三層慣例。混層會讓 body 隨開發過程腐化、與最終實作分歧：

| 層級 | 內容 | 載體 |
|------|------|------|
| **永久事實** | Problem、Expected、DoD、定案後的 Design Rationale | Body |
| **過程討論** | Implementation Plan、多方案優劣比較、brainstorming | Comments |
| **執行 status / 排序** | 「在哪個分支」「等 review」「已 merge」、優先級、開發階段 | Labels（status / `priority/p1` / `phase/v1`）、Linked PR、Milestone（`v1.2.0` / `2026-Q2`）、`Closes #N`（皆不寫進 body） |

> Milestone 命名與生命週期見 [`../release-management/SKILL.md` §1.5](../release-management/SKILL.md)。Issue 端唯一額外規則：父 issue 與其 sub-issue 綁同一 milestone（或子不綁），避免子散綁不同 milestone 破壞「父 = 整體驗收節點」語意。

> **Why 優先級 / 階段走 Label / Milestone 而非 body**：(1) 與 tense-neutral 同源——優先級會隨 roadmap 演進而 drift，body 卻被視為「永久事實」；(2) body 真要分群時用 milestone 綁定的版本語意（如 `v1.2.0`、`2026-Q2`），避開 `P1` / `P2` 這類會 drift 的標籤；長期未排程的項目走 Project board 或 `backlog` label，不開永久 milestone（milestone 必須有交付窗口，見 [`../release-management/SKILL.md` §1.5](../release-management/SKILL.md)）。
>
> **Why 過程討論留在 comments**：Plan 在開發中經常微調，寫進 body 會跟最終實作不一致；comments 有時序，自然反映演進，body 則須隨時可信。
>
> **定案回灌**：判準依影響範圍分流——
> - **輕量 rationale**（影響限於本 issue，例如「為何選方案 A 而非 B」）→ body 加 `## Proposed Solution` 區段，後續接手者只看 body 即可掌握「現狀 + 解法」
> - **重大架構決策**（跨 issue / 長期被引用）→ 走 **ADR**（`docs/adr/NNNN-*.md`）或 RFC document，不塞 issue body。issue 關閉後 body 沉在 closed list，ADR 才是 architectural source of truth
> - **單次實作步驟** → 留在 comments，不回灌
>
> **例外**：design / RFC issue 的大型 solution 段不適用上表「Expected + DoD → Body」的預設配置，改走下方「Design issue 變體」。

### Design issue 變體：solution 拆 comment

**觸發條件**（任一成立）：(a) body 預估 > 200 行；(b) solution 段（含 API spec、決策表、DoD）顯著大於 Problem 段。一般 feat / fix / docs issue 不觸發，仍走主表格。

觸發後改用以下分工：body 只留 **Problem + References**，Expected + DoD + 解法設計改貼成單一 top comment。

| 載體 | 內容 |
|------|------|
| **Body** | Problem（為什麼要做）、References（學術 / 規範依據）、Refs（相關 issue）|
| **Top comment** | Expected（API shape / 契約）、DoD checklist、決策表 / rationale |

> DoD 即使住在 comment，**checkbox 勾選規範仍適用**（見 §4）：中小型 Issue 可勾選追蹤，大型 Issue 由 sub-issue 完成度作為 SSOT 且 checkbox 保持不勾。

**Why**：(1) body 過長時 GitHub UI 會自動 fold，Problem 與 solution 都被收起來，等於兩段都看不到；(2) solution 在 design 階段會迭代，改 comment（保留時序）比 force-push 改 body 更乾淨；(3) Problem 是 issue 永久 anchor，被 `Refs #N` 引用時讀者要先看到的是「在解什麼問題」而非實作細節。

### Sub-issue：當 issue 太大需要拆分

當 issue 範圍過大（無法一個 PR 完成、或需多人並行），拆成**父 + 子 issue**，每個子 issue 對應獨立可 merge 的 PR。

**機制**：**預設用 GitHub 原生 Sub-issues**（2024-10+）——UI 自動顯示子 issue 開/關狀態、進度 bar，不污染父 body。建立方式：

- **UI**：父 issue 頁面下方「Create sub-issue」按鈕
- **Programmatic**：GraphQL `addSubIssue` mutation（需 `GraphQL-Features: sub_issues` preview header；`issueId` / `subIssueId` 為 **Node ID** 而非 issue number）

  ```bash
  gh api graphql -H "GraphQL-Features: sub_issues" \
    -f query='mutation { addSubIssue(input: {issueId: "<parent-node-id>", subIssueId: "<child-node-id>"}) { subIssue { number } } }'
  ```

  > **Node ID 取得**：`gh issue view <N> --json id -q .id`（或 GraphQL `repository(...) { issue(number:N) { id } }`）。`sub_issues` 為 **preview header**，GitHub 將來正式 release 後可能不再需要——若命令突然回 schema error 先檢查此 header。

若 repo 尚未啟用原生 Sub-issues（舊版 GHES / org 設定未開），退而在父 body 標準模板下方加 task list：

```markdown
## Sub-issues
- [ ] #<id> <子任務 A>
- [ ] #<id> <子任務 B>
```

兩種方式都**不會**自動關閉父 issue（避免提前丟失整體驗收節點）。

| 規則 | Why |
|------|-----|
| 子 issue 必須**獨立可 merge** | 假拆分讓子 PR 互相依賴，無法平行推進，失去拆分意義 |
| 子 PR 用 `Closes #<sub-id>`，不關父 | 父應在「整體驗收完成」時人工關閉，提前自動關會丟追蹤點 |
| 父 body 不嵌入子 PR SHA / 分支名 | 違反 §4 tense-neutral；GitHub 已自動渲染 task list 連結 |
| 子 branch base 在 main，不 nest 在父 branch | Nested branch 會卡 merge 順序、conflict 倍增 |

## 3. PR 工作流

**建立前**：分支已同步最新 main（rebase 或 merge 視團隊政策）、測試通過、無 conflict、commit 歷史符合 atomic。

**標題**：遵循 Conventional Commits、< 70 字元，結尾可帶 `(#issue)`。範例：`feat(auth): support OAuth login (#42)`（GitHub squash 時會自動 append `(#PR-number)`，與 issue `(#N)` 並存無妨；CHANGELOG 條目改用 PR number — 見 [`../release-management/SKILL.md` §3.1](../release-management/SKILL.md)）

### 描述模板

```markdown
## Summary
- <1-3 bullet points 描述變更>

## Test plan
- [ ] <驗證項目>

Closes #<issue-number>
```

> **`Closes #N`** 必寫於描述末——merge 後 GitHub 自動關閉 issue，避免人工漏關。
>
> **`Closes` 只寫在 PR description**（與 squash commit message）；**commit body 中若需引用 issue，用 `Refs #N`** — `Closes` 寫在 commit body 也會被 GitHub 解析觸發關閉，造成 atomic commit 流程中提前關閉 issue。
>
> **PR body 禁止 bot trailer**（`Generated with [Claude Code]`、`Co-Authored-By: <bot>` 等）：規則與 Why 見父層 [`../SKILL.md` §跨 skill 風格規範](../SKILL.md)，`gh pr create` 前掃 body 末尾刪除。

## 4. Issue / PR Body 紀律：Tense-Neutral

> 本節聚焦「**不該寫進 body 的 status 字句**」反面紀律；內容該落於 body / comments / GitHub 機制的正面路由見 §2「Body vs Comments 分工」。

Body **只寫永遠為真的事實**（內容範疇見 §2 三層分工表「永久事實」列）。**不要**嵌入 commit SHA、分支名、或「awaiting PR」「shipped on X」等 status 字句。

**Why**：(1) GitHub 已用 `(#N)` 反向連結 + Linked PR sidebar 自動串連，body 再寫一次冗餘；(2) squash-merge 後 SHA 變、分支被刪，status 字句立刻 rot；(3) 製造維護債——要記得回來改否則語意不一致。

**Status 字句常見變形（皆應改用 GitHub 機制：Labels / Linked PR / `Closes #N`）**：

- 「目前進度到哪」「在哪個分支」「awaiting PR to main」「shipped on X」
- DoD 綁分支：`- [x] tests on feat/X branch`（DoD 應為 spec 而非分支狀態）
- commit SHA：`be50883`（squash 後即 rot）

> **DoD checkbox 勾選規範**（平衡進度追蹤與維護性，非業界一成不變之慣例）：
> 1. **中小型 Issue（單 PR 可完成）**：可直接勾選 body/comment 中的 DoD checkbox 以利直覺追蹤。
> 2. **大型 Issue（需拆分多 PR）**：DoD checkbox 保持不勾（避免頻繁修改 body 違反 tense-neutral 與產生衝突），改走 §2 Sub-issue 拆分，由 GitHub 原生 sub-issue 完成度顯示作為 SSOT。
> 進入既有專案時，先確認當地慣例再決定是否套用此規則。

## 5. Merge 策略

> **無預設**：merge 觸發時用 AskUserQuestion 讓使用者從下表三選項中選擇，避免靜默套用某一策略而犧牲 atomic commit / body discipline。

| 策略 | 適用情境 | Why |
|------|----------|-----|
| **Squash merge** | 一般 feature / fix PR；team 文化以「PR = revert 單元」 | main 線性、操作簡單。本 skill 的 atomic / body discipline 主要在 PR review 階段創造價值，squash 後不延續到 main |
| **Rebase merge** | 單作者短分支、commit 已 atomic；希望 atomic discipline 延續到 main（bisect、fine-grained revert） | 線性歷史 + 保留每個 commit；風險：rewrite SHA、conflict 解決需 force-push PR 分支 |
| **Merge commit** | 長期 feature 分支、需保留多人協作 commit 歷史 | 保留分支結構作為 review 紀錄；main 變 branchy |

> **判準**：你或團隊實際是否 `git bisect` 到比 PR 更細的粒度？是 → rebase merge 划算；否 → squash 的操作成本通常勝過失去的細粒度。

### Squash merge 訊息（若使用者選 squash）

GitHub 預設會把「PR 標題 + 全部 commit 訊息」灌進 squash message。**必須覆寫** body 為：

```
<type>(<scope>): <description> (#<issue-number>)

<簡述變更與 Why，1-3 行>
```

> Issue 關閉由 PR description 的 `Closes #N` 自動觸發，squash body 不需重複；commit body 引用 issue 改用 `Refs #N`。

| Don't | Why |
|-------|-----|
| 保留預設 commit 列表 dump | main log 變雜訊，看不出這次 PR 真正做了什麼 |
| Squash 訊息違反 Conventional Commits | 任何 changelog / SemVer 工具（commitizen、semantic-release 等）都需要正確 type 才能分類 |
| Squash body 殘留 bot trailer（`Co-Authored-By: <bot>`、`Generated with [Claude Code]` 等） | GitHub squash UI 會聚合 PR commits 的 trailer，即使個別 commit 已乾淨仍可能被外層 prompt 範例注入；merge 前需檢視並刪除（規則與 Why 見父層 [`../SKILL.md` §跨 skill 風格規範](../SKILL.md)） |

## 6. 禁止事項與安全

未經使用者明確許可，**禁止**：

| 禁止 | Why |
|------|-----|
| Force push（任何情境，特別是 main） | 覆寫共享 / 他人歷史 |
| Amend 已推送的 commit | 改寫共享歷史 |
| `--no-verify` | 跳過 pre-commit hooks |
| `git reset --hard` / `clean -f` / `checkout .` / `restore .` | 丟失未提交或未追蹤的變更 |

安全：提交前確認無敏感資訊（`.env`、credentials、private keys）；用 `.gitignore` 排除敏感檔；大型二進位用 Git LFS；不提交 IDE 設定檔。

## 提交前檢查清單

- [ ] 分支名稱符合 `<type>/<description>`、全小寫、`-` 分隔、非個人名？
- [ ] Issue 標題祈使句、描述性、< 70 字元、無 status 字句、無 emoji、與 repo 語言一致？
- [ ] 大型 issue 已拆 sub-issues（預設 GitHub 原生 Sub-issues；不支援時用 task list fallback），且子 issue 各自獨立可 merge？
- [ ] Commit 訊息遵循 Conventional Commits（見對應 skill）？
- [ ] PR 標題 < 70 字元、遵循 Conventional Commits？
- [ ] PR 描述末有 `Closes #N`（子 issue 用子 id，不關父）？commit body 中引用 issue 改用 `Refs #N`？
- [ ] Issue / PR body 只寫永遠為真的事實（spec / DoD / 定案 rationale），無 SHA / 分支名 / 進度字句？
- [ ] Implementation Plan、多方案比較、brainstorming 已寫在 comments 而非 body？
- [ ] DoD checkbox 符合規範（中小型 Issue 可勾選追蹤；大型 Issue 未被勾選，由 sub-issue 完成度作為 SSOT）？
- [ ] Merge 觸發時已用 AskUserQuestion 詢問使用者選擇策略（squash / rebase / merge commit）？若選 squash，訊息已覆寫為 Conventional Commits 格式（不留預設 dump）？
- [ ] 未經許可未使用禁止操作（force push、`--no-verify`、`reset --hard` 等）？
- [ ] 沒有敏感資訊被提交？
