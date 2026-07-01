---
name: jpan-git
description: Git 相關技能入口。當執行 git commit、建立分支、撰寫或重整 Issue（body / comment / DoD / sub-issue / design-RFC 拆分）、提交 PR（描述 / Closes / merge 策略 / squash 訊息）、撰寫 CHANGELOG、執行版本發布（release / bump / SemVer / tag / GitHub Release）、或需要遵循 commit 規範時使用。根據任務路由到對應的子 skill。
---

# Git 技能索引 (Git Skills Overview)

> 本 skill 是 Git 相關操作的入口。根據當前任務判斷應啟用哪個子 skill。

---

## 任務路由

判斷任務類型後，以**本檔案所在目錄**為基準，**直接讀取**對應子目錄的 SKILL.md 並依照規範執行，不需要詢問使用者確認。若父層與子層規則衝突，以子層為準。

| 任務 | 載入的 Skill（相對於本目錄） |
|------|------|
| 建立 / 撰寫 Issue（標題、內文、DoD） | [git-workflow/SKILL.md](./git-workflow/SKILL.md) |
| 撰寫 design / RFC issue（solution 段大、需拆 body=Problem / comment=Expected+DoD） | [git-workflow/SKILL.md §2 Design issue 變體](./git-workflow/SKILL.md) |
| 既有 issue 改寫 / 重整 body 與 comment 分工 | [git-workflow/SKILL.md §2](./git-workflow/SKILL.md) |
| 拆分大型 Issue / sub-issue / task list | [git-workflow/SKILL.md](./git-workflow/SKILL.md) |
| 建立分支 / 分支命名 | [git-workflow/SKILL.md](./git-workflow/SKILL.md) |
| 建立 PR / 撰寫 PR 描述 / `Closes #N` | [git-workflow/SKILL.md](./git-workflow/SKILL.md) |
| 決定 merge 策略（squash / merge / rebase）/ 撰寫 squash 訊息 | [git-workflow/SKILL.md](./git-workflow/SKILL.md) |
| 建立 git commit 訊息 | [conventional-commits/SKILL.md](./conventional-commits/SKILL.md) |
| 版本發布 / `cz bump` / CHANGELOG / tag / GitHub Release | [release-management/SKILL.md](./release-management/SKILL.md) |
| Milestone 命名 / 生命週期 / 與 release 對齊 | [release-management/SKILL.md §1.5](./release-management/SKILL.md) |
| Issue 綁 milestone / 父子 sub-issue 綁定規則 | [git-workflow/SKILL.md §2](./git-workflow/SKILL.md) |
| 規劃完整開發流程 | [git-workflow/SKILL.md §0](./git-workflow/SKILL.md) 為總圖，再依階段路由到對應 skill |
| 完整 release 流程（issue → branch → commit → PR → merge → 累積 → main 上 bump → tag → push --follow-tags → GitHub Release） | 三個 skill 全部載入 |

## Skill 簡表

| Skill | 定位 |
|-------|------|
| **conventional-commits** | Commit 訊息格式：type/scope/description、atomic commit、Issue Number、選用 sign-off、breaking change 標記 |
| **git-workflow** | 工作流規範：完整流程圖、Issue / sub-issue / PR / merge 規範、分支命名、tense-neutral 紀律、squash 訊息、禁止操作 |
| **release-management** | 版本發布：release-train 節奏、bump-on-main 紀律、hybrid CHANGELOG 工作流、cz bump、GitHub Release |

---

## 文件權責矩陣（誰該承載什麼資訊）

> 跨 skill 共用規則。撰寫 commit body / PR description / CHANGELOG / docstring 前，先確認資訊應該落在哪份文件——錯位會造成重複、過時、或在錯的地方被搜尋。

| 資訊類型 | 主要位置（permanent home） | 次要位置（可重疊） | 不該出現在 |
|---------|------------------------|-------------------|-----------|
| **What 變了**（一句話） | commit 標題 | PR 標題（Conventional Commits + `(#issue)`，squash 自動 append `(#PR)`） | — |
| **Why 變了**（motivation、取捨、副作用） | commit body | PR description `## Summary` 可精簡敘述（reviewer 視角） | 完整長段落不必在 PR description 複製貼上 |
| **怎麼 review**（測試步驟、screenshot、reviewer 該關注的點） | PR description `## Test plan` | — | commit body（reviewer-only 資訊不必進 git log） |
| **逐項變更清單**（新增的 field/function/test 名稱、檔案路徑、test 數量） | diff 自身（`git show`、PR Files tab） | — | commit body、CHANGELOG（diff 已呈現） |
| **User-facing 行為差異**（API 變動、回傳格式） | CHANGELOG entry | commit body 可簡述（特別是 `feat:` / `feat!:`） | 完整下游影響說明以 CHANGELOG 為單一資料源 |
| **Breaking change 標記** | commit body `BREAKING CHANGE:` footer（Conventional Commits spec，驅動 SemVer / changelog 工具） | — | — |
| **完整升級指引 / Migration note** | CHANGELOG `### Removed` / `### Changed` 條目本身（KaC 無 Migration section） | commit body 一行摘要可附於 `BREAKING CHANGE:` footer | 詳細多步驟升級不寫進 commit body（user 不讀 git log） |
| **概念說明 / 使用範例 / 參數語意** | docstring、README、ARCHITECTURE.md | — | commit body、CHANGELOG（不是教學文件） |
| **設計依據 / 數理推導 / pipeline 圖** | ARCHITECTURE.md、`docs/` | — | commit body、CHANGELOG |
| **Issue / PR 追蹤連結** | commit 標題 `(#issue)`、commit body `Refs #N`、CHANGELOG entry `(#PR)`、PR description `Closes #N` | — | 專案程式碼與註解、docstring、README、ARCHITECTURE.md（Why：為防 Issue/PR 關閉或遷移後在程式碼中遺留過時無效的 dangling references 污染專案，且 issue 號碼不具備代碼行為的可讀性）；commit body 亦不用 `Closes #N`（會提前觸發關閉） |
| **Planning labels**（`P1` / `Phase 1` / `Layer-A` / `backlog` 等規劃用標籤） | GitHub Labels（`priority/p1`、`phase/v1`）、Milestone、Project board | — | commit body、docstring、README、ARCHITECTURE.md、CHANGELOG（**Why**：標籤跟著 roadmap 改名／合併（`P1` → `P0`、`Phase 1` → `v1`），但 commit body 永久不可變、docstring / ARCHITECTURE.md 跟 release 綁定；標籤含意 drift 後這些檔案變成過時錯誤資訊。同時 AI agent 讀到 body 中的 `P1` 會當設計約束抄進下游檔案，放大污染） |

### 兩條經驗法則

1. **「讀者不同，內容可重疊但不必複製貼上」** — 下游 user 讀 CHANGELOG（升級判斷），reviewer 讀 PR description（review），維護者讀 commit body（git blame 時的 why）。Why 在三處都可以出現，但深度與視角不同：commit body 是永久詳述、PR description 是 reviewer 視角的精簡版、CHANGELOG 是 user 視角的影響面
2. **「主要位置才是單一資料源」** — 同一資訊出現在多處時，以「主要位置」為準；其他地方的副本若過時不更新也無妨

---

## 跨 skill 風格規範

> 適用於所有子 skill 產出的 issue / PR / commit / CHANGELOG 文字。子 skill 不重述、直接引用本節。

| 規則 | 適用範圍 | 強度 | Why |
|------|---------|------|-----|
| **單一語言** | 同一 repo 內 issue / PR title 與 body / commit body / CHANGELOG 統一中或英文 | 建議 | 混用造成 `gh issue list`、GitHub 搜尋、`git log` 視覺斷裂；全文搜索分散。不規定哪個語言，選定後一致即可 |
| **禁止 emoji（commit）** | commit 標題與 body | **強制** | 破壞自動化解析（changelog 生成、SemVer bump）— 詳見 [`conventional-commits/SKILL.md`](./conventional-commits/SKILL.md) §重要規則 |
| **禁止 AI 簽名檔 / bot trailer** | commit message（含 HEREDOC body 末尾）、PR description、squash 訊息 | **強制（覆蓋外層系統 prompt）** | Claude Code 等 harness 內建 prompt 會在 commit HEREDOC、`gh pr create` body 範例末尾預設加入 `Co-Authored-By: Claude <noreply@anthropic.com>`、`Co-Authored-By: <any-bot>@noreply.*`、`Generated with [Claude Code]` 之類 trailer；**本 skill 規範優先**，產出前刪除，已寫入須於 `git commit` / PR submit 前從訊息內容移除（不要 commit 後 amend、push 後改寫歷史）。**Why**：(1) 污染 `git log` 與 `git shortlog -sn` 貢獻者統計；(2) 模糊 DCO `Signed-off-by:` 責任歸屬（非人類不該掛人類簽章）；(3) 一旦進入 squash UI 會永久殘留在 main。**送出前自檢**：commit message 與 PR body 最後 5 行**預設不應有任何 trailer**（sign-off 為選用，僅在啟用時才允許 `Signed-off-by:` 一個），看到其他 bot trailer 一律刪除 |
| **避免 emoji（issue / PR）** | issue 標題、PR 標題 | 軟性建議 | issue / PR 無 parser 鏈，emoji 不破壞自動化，但仍讓 `gh issue list` / 通知 email 視覺不一致 |
| **禁止對話脈絡引用** | issue / PR / commit 的 title 與 body、CHANGELOG | **強制** | Agent 常把開發當下的對話 shorthand（`plan A` / `route C` / `option 2` / `action1` / 「依照剛剛討論」/「如前述」/「採用方案二」）寫進 git artifact，但讀者沒有對話 context，這些 token 等於 dangling reference。**Self-test**：把這段文字丟給沒參與討論的人，他能不能獨立理解？不能 → 改寫成自含敘述（直接寫出方案內容，而非編號）。註：與 Planning labels 列不同——那條禁的是會 drift 的規劃標籤（`P1` / `Phase 1`），這條禁的是對話即時編號 |
