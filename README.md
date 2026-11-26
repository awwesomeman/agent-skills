# agent-skills

跨 Agent 使用的 AI Skills（Claude Code、Codex、Gemini CLI、Cursor、GitHub Copilot 等），只放工具預設不會做、不講就會出錯的慣例。

## 技能

| Skill | 何時載入 | 內容 |
|-------|----------|------|
| [jpan-dev-conventions](./skills/jpan-dev-conventions/SKILL.md) | commit、開 PR、審查合併、派子代理、寫文件、回報與引用、不可逆或公開的動作之前 | repo 規則優先、不加 AI 署名、一個 PR 一個 commit、批准與安全、派工與審查、查證與來源、文件寫法、任務追蹤（附 `TASKS.local.md` 範本） |
| [jpan-quant-research](./skills/jpan-quant-research/SKILL.md) | 設計實驗、測試因子或策略、寫回測或特徵程式、回報研究結果之前 | 事前登錄與試驗計數、忠於原方法、前視與時間戳、成交真實性 |

repo 的 `AGENTS.md` 放該 repo 專屬的規定（批准者、上限、標籤、語言），與技能不同時以 `AGENTS.md` 為準。必須每次生效的規則（例如不加 AI 署名）也應寫進 `AGENTS.md`，因為技能要由模型決定是否載入。

## 安裝

兩種範圍：

- **全域**：所有專案都載入，個人慣用的技能裝這裡
- **專案**：只在該專案載入，設定可隨 repo 共享給協作者

### Claude Code

```bash
claude plugin marketplace add awwesomeman/agent-skills
claude plugin install agent-skills@awwesomeman                   # 全域（預設 --scope user）
claude plugin install agent-skills@awwesomeman --scope project   # 專案：在專案根目錄執行
```

`--scope` 只決定啟用設定寫在哪個設定檔，不接受路徑；plugin 檔案一律存放在 `~/.claude/plugins/cache/`。

| `--scope` | 寫入 | 生效範圍 |
|---|---|---|
| `user`（預設） | `~/.claude/settings.json` | 所有專案 |
| `project` | 目前專案的 `.claude/settings.json` | 該專案，隨 repo commit，協作者開啟時會提示安裝 |
| `local` | 目前專案的 `.claude/settings.local.json` | 該專案、只有自己，不 commit |

安裝或更新後執行 `/reload-plugins` 或重開 session 生效。

在 session 內也可用 `/plugin marketplace add ...`、`/plugin install ...`。技能以 `/agent-skills:jpan-dev-conventions` 等名稱呼叫。

### 其他 Agent

[`npx skills`](https://github.com/vercel-labs/skills) 可安裝到 Codex、Gemini CLI、Cursor、GitHub Copilot、Antigravity 等支援 Agent Skills 的工具，依各工具的規定放到對應目錄：

```bash
npx skills add awwesomeman/agent-skills -g    # 全域
npx skills add awwesomeman/agent-skills       # 專案：在專案根目錄執行
npx skills add awwesomeman/agent-skills -g -a codex -a antigravity --skill jpan-dev-conventions
```

- 不加 `-g` 也不加 `-y` 時，會互動詢問範圍；不加 `-a` 時，自動偵測已安裝的工具或互動選擇
- 專案範圍多數工具共用 `.agents/skills/`，Claude Code 為 `.claude/skills/`；全域路徑各工具不同（例如 Codex `~/.agents/skills/`、Antigravity `~/.gemini/config/skills/`），完整對照見 [skills 的 agent 清單](https://github.com/vercel-labs/skills/blob/main/docs/agents.md)
- 預設以 symlink 指向一份共用副本；要各自複製加 `--copy`
- 安裝路徑由各工具的規定決定，沒有自訂路徑的選項；Claude Code 內執行 `/reload-skills` 或重開 session 生效

### 固定版本

發版以 `vX.Y.Z` 打 tag，需要可重現的環境時固定 tag：

```bash
claude plugin marketplace add awwesomeman/agent-skills#vX.Y.Z
npx skills add awwesomeman/agent-skills@vX.Y.Z
```

### 更新

plugin 不宣告固定的 `version`，`main` 上每個新 commit 都算新版本。

```bash
# Claude Code：先更新 marketplace，再更新 plugin（重開 session 生效）
claude plugin marketplace update awwesomeman
claude plugin update agent-skills@awwesomeman

# 其他 Agent
npx skills check
npx skills update
```

Claude Code 對第三方 marketplace 預設不自動更新，可在 `/plugin` > Marketplaces 開啟。

### 重新安裝

舊版的 `git`、`python`、`quant`、`skill-creator` 技能與 `install.sh` 系列腳本已移除，內容濃縮進上面兩個技能。

- **用 `install.sh` 或 `remote-install.sh` 裝過**：從各工具的 skills 目錄刪除 `git`、`python`、`quant`、`skill-creator` 與 `.agent-skills` 標記目錄，再用 `npx skills add` 重裝
- **Claude Code plugin**：執行上方的更新指令

## 新增技能

每個技能是 `skills/<name>/SKILL.md`，frontmatter 的 `name` 等於目錄名，只用 [Agent Skills 規範](https://agentskills.io/specification) 允許的欄位。CI 以 `agentskills validate` 與 `claude plugin validate .` 檢查；本機可先跑：

```bash
find skills -name SKILL.md -exec dirname {} \; | xargs -n1 uvx --from skills-ref agentskills validate
claude plugin validate .
```
