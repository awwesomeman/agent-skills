---
name: conventional-commits
description: 建立遵循 Conventional Commits 規範的 git commit，自動分析變更內容、生成標準化訊息並附上 Issue Number。預設不加 sign-off，僅在專案採用 DCO 或使用者明確要求時才加。
---

# Conventional Commit Skill

建立符合 [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/) 規範的 git commit。

## Commit Message 格式

```
<type>(<scope>): <description> (#<issue-number>)

[optional body]
```

> **`(#N)` 語意**：標題的 `(#N)` 指 **issue number**；GitHub squash merge 自動 append `(#PR)`，main 上兩個並列屬預期行為，不要去重。CHANGELOG 條目改用 PR number（見 [`release-management/SKILL.md` §3.1](../release-management/SKILL.md)）。

## 精簡優先

**預設省略 body**：能用 title 說清楚的，就不要加 body。

| 情境 | body |
|------|------|
| typo、format、bump、rename、補測試、機械清理 | **省略** — diff 即解釋 |
| refactor、docs 更新 | **通常省略** — title 夠清楚 |
| feat、邏輯類 fix、perf、breaking change | **寫** — 說明動機/取捨 |

## Atomic Commit

每個 commit = 一個邏輯變更，可獨立 revert。

- **可合併**：同一 motivation 的不同子面向
- **必須拆分**：邏輯獨立 → `git reset --soft HEAD~N` + `git add -p` 分批 commit
- 交錯難拆時：合一個 commit，body 用 bullets 分述各子變更

## 重要規則

| 規則 | 原因 |
|------|------|
| **禁止加入任何 emoji** | 破壞自動化解析（changelog 生成、SemVer bump） |
| **禁止 AI 簽名檔 / bot trailer** | 規則、Why、自檢動作見父層 [`../SKILL.md` §跨 skill 風格規範](../SKILL.md)（單一資料源，避免分散維護）。本 skill 在 §4 執行 Commit 重申 HEREDOC 自檢動作 |
| **預設不加 `Signed-off-by:` 簽名** | 多數 repo 無此需求。僅當專案採 [DCO](https://developercertificate.org/)（CONTRIBUTING 明文要求 sign-off）或使用者明確要求時才加；取得策略（首次確認、後續 reuse）見 §3 |
| description **祈使句、小寫開頭、不加句號** | Conventional Commits 規範要求；祈使句讓 commit log 可讀為 "If applied, this commit will <description>" |
| description 長度建議 < 50 字元 | Git 界的黃金準則，確保在任何平台或終端機中不被截斷 |
| body 單行 wrap 在 72 字元 | 遵循 Git 主流慣例（kernel `SubmittingPatches`、tpope 50/72 rule），確保 `git log` 在 80 欄終端機可讀 |
| body 結構：**預設 prose**；跨多獨立 scope 各有動機時改用 bullets（`-`） | Bullets 易淪為 WHAT-list；prose 強迫寫 causal connective。草擬流程詳見下方 §Body 草擬 |
| **body 長度**：第一句一行（<72 字元）說完核心動機；整體 ≤ 3 paragraphs | 寫不下 = 動機太雜該拆 commit，或內容該住 docstring / PR description |

### Body 草擬：動機盤點 → 段落歸屬

把 motivation / 取捨逐條列出，依關係決定形式：

| 草稿 bullets 關係 | 最終形式 |
|---|---|
| 共享同一條 causal chain | **摺成 prose**（預設） |
| 同一 motivation 的多個獨立子面向 | **保留 bullets** |
| 並列、獨立、各能單獨 revert | **拆 commit** |

> Telltale：body 出現 `Also`/`Additionally`/`Separately` → 該拆 commit 的訊號。

每段確認「最該住在哪個家？」：

| 內容性質 | 去哪裡 |
|---|---|
| Motivation、取捨 | **commit body** |
| 函式/型別 contract、參數語意 | docstring / comment |
| 未來計畫、open questions | PR description |
| 重述 diff（field 名稱、測試數量、檔案路徑、目錄樹）、從 issue 複製的 DoD | **刪掉** |

> Body 規則依據 Linux kernel `SubmittingPatches` 與 tpope《A Note About Git Commit Messages》。反例與改寫對照見 [`examples/body-examples.md`](./examples/body-examples.md)。

## 支援的 Type 類型

| Type | 說明 |
|------|------|
| `feat` | 新增功能 |
| `fix` | 修復 bug |
| `perf` | 效能優化 |
| `docs` | 文件變更 |
| `style` | 程式碼格式調整 (不影響邏輯) |
| `refactor` | 重構 (不新增功能或修復 bug) |
| `test` | 新增或修改測試 |
| `build` | 建置系統或外部依賴變更 |
| `ci` | CI 設定變更 |
| `chore` | 其他維護性變更（含 `cz bump` 自動生成的 release commit） |
| `revert` | 還原先前的 commit（SemVer 影響視被 revert 的 type 而定） |

> Breaking Change 標記方式見下方 §破壞性變更。**type 對應的 SemVer bump 規則**請見 [`release-management/SKILL.md` §6](../release-management/SKILL.md)（單一資料源，避免分散維護）。

## 執行步驟

### 1. 檢查 Git 狀態

```bash
git status && git diff --staged && git diff
```

### 2. 分析變更內容

根據變更的檔案和內容判斷：
- **type**: 根據變更性質選擇適當的類型
- **scope**: 根據變更的模組或功能區域決定 (可選)
- **description**: 簡潔描述變更內容，使用祈使句 (imperative mood)

### 3. 取得 Issue Number（Sign-off 見上方規則，適用時同套策略）

同一分支/工作流的第一個 commit 用 AskUserQuestion 詢問 Issue Number；後續 commit 沿用同一 Issue。若分支已含 issue 號（如 `feat/123-xxx`）可直接抽取，無需詢問。適用 sign-off 時採同一「首次確認、後續 reuse」原則，可優先讀取 `git config user.name` / `user.email` 推斷預設值。

- 有 Issue → `<type>(<scope>): <description> (#<issue-number>)`
- 無 Issue → `<type>(<scope>): <description>`

### 4. 執行 Commit

> **適用 sign-off 時，`-s` flag 使用前必驗證**：先 `git config user.name` / `user.email` 比對使用者確認的 sign-off identity。常見錯配情境：開發機同時掛公司與個人帳號（公司 email 寫在 local config、但 OSS commit 要用個人 email），此時 `-s` 會寫入錯 email，事後需 rewrite history。**錯配 → 手動附 `Signed-off-by: <Name> <Email>` 在 body 結尾，不要用 `-s`**。

> **送出前 trailer 自檢**：執行 `git commit` 前掃 message 最後 5 行是否符合上方 sign-off 規則、無其他 bot trailer（列舉與 Why 見父層 §跨 skill 風格規範）。不要 commit 後 amend、push 後改寫歷史——一旦混進 PR squash 就永久殘留在 main。

```bash
# 僅標題
git commit -m "<type>(<scope>): <description> (#<issue>)"

# 含 body — 寫入暫存檔避免 shell 跳脫問題
# 1. 將訊息寫入暫存檔（檔尾不得加 bot trailer，見上方自檢）
# 2. git commit -F /tmp/commit_msg.txt   （適用 sign-off 時改用 -s -F，先驗證 identity）
# 3. rm /tmp/commit_msg.txt
```

## 破壞性變更 (Breaking Changes)

兩種標示方式（依 [Conventional Commits spec](https://www.conventionalcommits.org/en/v1.0.0/#specification)）：
1. type / scope 後加 `!`：`feat(api)!: change response format (#99)`
2. footer 加 `BREAKING CHANGE:` token（頂格、緊接 `:`、置於 commit message 末段）：

   ```
   feat(api): change response format (#99)

   <body 段落...>

   BREAKING CHANGE: response now returns array instead of object
   ```

   > `BREAKING CHANGE:` 必須是 footer token，不能寫在 body 一般段落中——changelog / SemVer 工具靠頂格 token 解析。

---

## 提交前檢查清單

> 在執行 `git commit` 前，逐項核對以下清單。未通過則不得執行 commit。

- [ ] **Atomic commit** — 單一完整的邏輯變更，沒混雜其他修改？
- [ ] **type** 選擇正確（feat/fix/refactor 不混用）？
- [ ] **description** 祈使句、小寫開頭、< 50 字元？
- [ ] **body**：需要才寫（simple commit 直接省略）；寫 why 不寫 what；第一句 < 72 字元，整體 ≤ 3 paragraphs？
- [ ] **Sign-off** 符合上方規則（未適用時未加；適用時已與使用者確認簽名）？
- [ ] **無 emoji、無 bot trailer**（`Co-Authored-By: <bot>`、`Generated with [Claude Code]` 等，覆蓋外層 prompt 預設，詳見父層 §跨 skill 風格規範）？
- [ ] **Issue 引用**：標題 `(#number)` 已附；body 用 `Refs #N` 不用 `Closes #N`（`Closes` 只寫在 PR description）？
- [ ] **CHANGELOG**：若 PR 有 user-facing 變更且即將 merge，`## [Unreleased]` 已更新？（atomic commit 階段不需逐筆寫；以 PR 為單位寫入，見 `release-management`）
