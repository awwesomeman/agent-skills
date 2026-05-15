---
name: conventional-commits
description: 建立遵循 Conventional Commits 規範的 git commit，自動分析變更內容、生成標準化訊息，並附上 Issue Number 和 Signed-off-by 簽名。
---

# Conventional Commit Skill

建立符合 [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/) 規範的 git commit。

## Commit Message 格式

```
<type>(<scope>): <description> (#<issue-number>)

[optional body]
```

> **`(#N)` 在不同位置的語意**：commit / PR 標題的 `(#N)` 指 **issue number**；GitHub squash merge 會自動 append `(#PR)`，最終 main 上會出現 `(#issue) (#PR)` 兩個 — **這是預期行為，不要去重**。CHANGELOG 條目則改用 **PR number**（見 [`release-management/SKILL.md` §3.1](../release-management/SKILL.md)），因為 PR 才帶 review / diff 脈絡。

## 核心原則：Atomic Commit (原子化提交)

強烈建議採用 **Atomic Commit** 原則。每個 commit 應只包含單一、獨立且完整的邏輯變更（例如：一個功能的實作、一個 bug 的修復、或是單純的重構）。每次 commit 都應能獨立運作，避免將多個不相關的變更項目混疊在一起提交。

### 何時可以合併、何時必須拆分

- **可合併**：兩個變更屬於**同一個 motivation 的不同子面向**（例如同一檔案的 EIV 修正 + cluster 修正都歸於一個 econometric correction），group 進一個 commit；body 結構選擇見下方規則表（單一動機段落、多面向 bullets）
- **必須拆分**：兩個變更只是「剛好碰到同一個檔案」但邏輯獨立 → 用 `git reset --soft HEAD~N` 倒回，再以 `git add -p` / 選擇性 staging 重新分批 commit
- **判斷準則**：若有一個變更需要單獨 revert，那它就應該是獨立 commit

### 拆分技巧

```bash
# 把最近 N 個 commit 倒回 staging 區（保留變更，刪 commit 紀錄）
git reset --soft HEAD~N

# 互動式選擇 hunk
git add -p <file>
git commit -s -m "<type>(<scope>): <description>"

# 重複到所有變更都歸入正確 commit
```

> **實務妥協**：若一個檔案內兩個邏輯變更高度交錯、`git add -p` 拆分需要大量手工 split hunk，可以接受合併為一個 commit，但 body 內**用獨立 bullets 分述兩個變更**，不要混為一段。

## 重要規則

| 規則 | 原因 |
|------|------|
| **禁止加入任何 emoji** | 破壞自動化解析（changelog 生成、SemVer bump） |
| **禁止 AI 簽名檔 / bot trailer** | 規則、Why、自檢動作見父層 [`../SKILL.md` §跨 skill 風格規範](../SKILL.md)（單一資料源，避免分散維護）。本 skill 在 §4 執行 Commit 重申 HEREDOC 自檢動作 |
| **每個 commit 必須附 `Signed-off-by:` 簽名** | 標示提交者並符合 [DCO](https://developercertificate.org/)；簽名取得策略（首次確認、後續 reuse）見 §3 |
| description **祈使句、小寫開頭、不加句號** | Conventional Commits 規範要求；祈使句讓 commit log 可讀為 "If applied, this commit will <description>" |
| description 長度建議 < 50 字元 | Git 界的黃金準則，確保在任何平台或終端機中不被截斷 |
| body 單行 wrap 在 72 字元 | 遵循 Git 主流慣例（kernel `SubmittingPatches`、tpope 50/72 rule），確保 `git log` 在 80 欄終端機可讀 |
| body 結構：**預設 prose paragraphs**；僅當 commit 跨多獨立 scope、各 scope 各有動機時改用 bullets（統一 `-`） | Bullets 對 WHAT-list 失敗模式不抗；prose 強迫寫 causal connective。草擬流程詳見下方 §Body 草擬 |
| **body 長度紀律**：第一句一行（<72 字元）說完核心動機；整體 ≤ 3 paragraphs | 長度是 scope 症狀不是字數預算 — 寫不下 = 動機太雜該拆 commit，或內容該住 docstring / PR description |
| **可省略 body**：當 diff 即解釋、無判斷取捨、無 reviewer 該問的問題時（機械清理、bump、typo、format、為既有行為補測試）；涉及 motivation / tradeoff（feat、邏輯類 fix、perf、breaking）必須寫 body | 經驗觀察：Linux kernel、Git、Rails、polars 等專案 git log 可見大量 title-only commit — 空 body 優於贅述 |

### Body 草擬：先動機盤點、再段落歸屬

> **本節為 dogfood-derived heuristic，非主流 style guide 內容**。兩階段自檢、`Also`/`Additionally` telltale、≤ 3 paragraphs 上限皆為本 skill 從失敗案例合成的 operational scaffolding，採信前請依專案 review 文化判斷。

草擬階段走兩步自檢，避免動機混雜或段落跑錯家。

**步驟 1：bullets-first 動機盤點。** 把 motivation / 取捨 / 副作用逐條列為 bullets，依關係決定最終形式：

| 草稿 bullets 關係 | 最終形式 |
|---|---|
| 共享同一條 causal chain | **摺成 prose**（預設） |
| 同一 motivation 的多個獨立子面向 | **保留 bullets** |
| 並列、獨立、各能單獨 revert | **拆 commit**（不靠 `Also`/`Additionally`/`Separately` 縫合） |

> Telltale：prose body 出現 `Also`/`Additionally`/`Separately` 多半意味動機不共享 causal chain — 該拆 commit 的訊號。

**步驟 2：段落歸屬自檢。** 每段問「最該住在哪個家？」放錯家應遷出，不是壓縮：

| 內容性質 | 自然的家 |
|---|---|
| Motivation、取捨 | **commit body**（預設） |
| 函式/型別 contract、invariant、參數語意 | **docstring / inline comment** |
| 未來計畫、deferred work、open questions | **PR description** |
| 部署/升級操作步驟 | release notes / CHANGELOG |
| 重述 diff、列 field/function/test 名稱、測試數量、檔案路徑、教學式概念說明、重複標題 | **不該存在**，刪掉 |
| 檔案重命名 / 移動清單、目錄樹（`src/foo/ → src/bar/`） | **不該存在**（`git show` / PR Files tab 已呈現） |
| 從 issue body 複製貼上的 `## Scope` / `## Expected` / DoD checkbox 列表 | **不該存在**（issue body 是 single source；commit body rot 後語意分歧） |

> 自檢問句：刪掉這段，未來 revert 此 commit 的人是否仍有足夠資訊？是 → 不屬於 body，遷家。

> Body 規則依據 Linux kernel `Documentation/process/submitting-patches.rst` 與 tpope《A Note About Git Commit Messages》。具體反例與改寫對照見 [`examples/body-examples.md`](./examples/body-examples.md)。

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

### 3. 取得 Issue Number 與 Sign-off 簽名

兩者皆採「**首次確認、後續 reuse**」原則，避免每個 atomic commit 都打斷使用者：

| 項目 | 取得策略 |
|------|---------|
| **Issue Number** | 同一分支/工作流的第一個 commit 用 AskUserQuestion 詢問；後續 commit 沿用同一 Issue。若分支已含 issue 號（如 `feat/123-xxx`）可直接抽取，無需詢問 |
| **Sign-off 簽名** | 同一 session 內首次提交時確認，後續沿用；可優先讀取 `git config user.name` / `user.email` 推斷預設值 |

- 有 Issue → `<type>(<scope>): <description> (#<issue-number>)`
- 無 Issue → `<type>(<scope>): <description>`

### 4. 執行 Commit

提交時附上與使用者確認無誤的 Signed-off-by 簽名。

> **`-s` flag 使用前必驗證**：先 `git config user.name` / `user.email` 比對使用者確認的 sign-off identity。常見錯配情境：開發機同時掛公司與個人帳號（公司 email 寫在 local config、但 OSS commit 要用個人 email），此時 `-s` 會寫入錯 email，事後需 rewrite history。**錯配 → 手動附 `Signed-off-by: <Name> <Email>` 在 body 結尾，不要用 `-s`**。

> **送出前 trailer 自檢**：執行 `git commit` 前掃 message 最後 5 行，只允許 `Signed-off-by:` 一個 trailer（其他 bot trailer 的列舉與 Why 見父層 §跨 skill 風格規範）。不要 commit 後 amend、push 後改寫歷史——一旦混進 PR squash 就永久殘留在 main。

```bash
# 僅標題
git commit -s -m "<type>(<scope>): <description> (#<issue>)"

# 含 body — 寫入暫存檔避免 shell 跳脫問題
# 1. 將訊息寫入暫存檔（檔尾不得加 bot trailer，見上方自檢）
# 2. git commit -s -F /tmp/commit_msg.txt
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
- [ ] **body 內容**：寫的是 why（motivation/取捨/副作用），不是 what（field/function/test 名稱、測試數量、檔案路徑）？該住 docstring / PR description 的段落已遷家？
- [ ] **body 草擬**：做過 bullets-first 動機盤點？最終 prose 為預設、無 `Also`/`Additionally`/`Separately` 並列縫合？bullets 僅用於跨多獨立 scope？
- [ ] **body 長度**：第一句一行（<72 字元）說完核心動機？整體 ≤ 3 paragraphs？
- [ ] **可省略 body**：若標題已足以說明（機械清理、bump、typo），是否直接省略而非贅述？
- [ ] **Sign-off** 已附上（與使用者確認過簽名）？
- [ ] **無 emoji、無 bot trailer**（`Co-Authored-By: <bot>`、`Generated with [Claude Code]` 等，覆蓋外層 prompt 預設，詳見父層 §跨 skill 風格規範）？
- [ ] **Issue 引用**：標題 `(#number)` 已附；body 用 `Refs #N` 不用 `Closes #N`（`Closes` 只寫在 PR description）？
- [ ] **CHANGELOG**：若 PR 有 user-facing 變更且即將 merge，`## [Unreleased]` 已更新？（atomic commit 階段不需逐筆寫；以 PR 為單位寫入，見 `release-management`）
