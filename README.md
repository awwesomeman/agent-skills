# agent-skills

跨 Agent 使用的 AI Skills 統一管理專案。

**Single Source of Truth** — 在這裡修改 skill，所有 AI 工具自動同步。

## 目錄

- [安裝](#安裝)
  - [方式一：Plugin（Claude Code、Antigravity CLI）](#方式一plugin)
  - [方式二：安裝腳本（所有工具）](#方式二安裝腳本)
  - [解除安裝](#解除安裝)
- [支援的 AI 工具](#支援的-ai-工具)
- [目錄結構](#目錄結構)
- [Quant Skills 概覽](#quant-skills-概覽)
- [新增 Skill 的 SOP](#新增-skill-的-sop)

---

## 安裝

兩種方式，擇一即可：Plugin 由工具自己管理更新，腳本則涵蓋所有工具。

### 方式一：Plugin

適用於支援 plugin marketplace 的工具。安裝後由工具本身負責更新，不需要保留 clone。

```bash
# Claude Code（CLI 與 VSCode extension 共用 ~/.claude，裝一次兩邊都有）
/plugin marketplace add awwesomeman/agent-skills
/plugin install agent-skills@awwesomeman

# Antigravity CLI
agy plugin install agent-skills@awwesomeman
```

更新：`/plugin marketplace update awwesomeman`。

### 方式二：安裝腳本

適用於所有工具，包含尚未支援 plugin 的 Codex、Cursor、Copilot 等。

```bash
git clone https://github.com/awwesomeman/agent-skills.git ~/agent-skills
cd ~/agent-skills
bash install.sh
```

> symlink 模式（預設）會指向此目錄，**移動或刪除 clone 會讓所有 skill 失效**，建議放在固定位置。

```
Usage: bash install.sh [OPTIONS] [AI_TOOLS...]
```

| 參數 | 縮寫 | 說明 | 預設 |
|------|------|------|------|
| `--skills <list>` | `-s` | 指定安裝的技能，逗號分隔 | 全部技能 |
| `--local` | `-l` | 安裝到「執行指令所在的目錄」（如 `./.claude/skills/`），而非全域 | 全域 |
| `--copy` | `-c` | 複製檔案取代 symlink，適用於無法保留 clone 的情境 | symlink |
| `--force` | `-f` | `install`：覆蓋既有目錄；`uninstall`：移除非本工具管理的路徑（預設需 TTY 確認） | 略過 |
| `--path <dir>` | `-p` | 直接安裝到指定目錄，跳過 AI 工具偵測 | 自動偵測 |
| `--yes` | `-y` | （僅 `uninstall.sh`）搭配 `--force` 跳過互動確認，用於 pipe/非互動情境 | 需確認 |
| `[AI_TOOLS...]` | — | 指定目標工具（可多個），名稱見[支援的 AI 工具](#支援的-ai-工具) | 偵測已安裝的工具 |

```bash
bash install.sh                          # 自動偵測，安裝全部技能
bash install.sh claude cursor            # 只裝到指定工具
bash install.sh -s "python,git"          # 只裝指定技能
bash install.sh --local                  # 裝到目前專案目錄下
bash install.sh --path "~/my-agent/skills"   # 裝到任意目錄
```

免 clone 的遠端安裝（預設即 `--copy`）：

```bash
BASE=https://raw.githubusercontent.com/awwesomeman/agent-skills/main
curl -fsSL $BASE/remote-install.sh | bash
curl -fsSL $BASE/remote-install.sh | bash -s -- -s "python,git" cursor claude
```

**必讀注意**

- **`curl | bash` 傳參要有 `-s --`**：否則 `| bash "claude"` 會被當成執行系統上的 `claude`，噴 `syntax error near unexpected token`。
- **`--path` 就是最終目錄**：不會自動補 `skills/`。若目標工具需要，請自己寫上 `--path "~/my-agent/skills"`。路徑含空白務必加引號，否則會被 shell 拆成位置參數、裝到截斷後的錯誤目錄。
- **指定工具名稱只會裝到「已安裝」的工具**，未安裝會印 `[WARN] ... not installed`。要寫入任意目錄請用 `--path`。
- **`--path` 蓋過 `--local` 與位置參數**（會印 `[WARN]`），且不做工具偵測。
- **`--force` 會 `rm -rf` 同名目錄**（含非本工具建立的）。`uninstall --force` 預設需 TTY 互動確認；`curl | bash` 無 TTY，須再加 `--yes`。
- **Fork 自用**：`GITHUB_REPO=user/repo curl -fsSL $BASE/remote-install.sh | bash`。

### 解除安裝

`uninstall.sh` 用法與 `install.sh` 對稱（`--local` / `--path` / `--skills` / 位置參數皆相同），會自動辨識 symlink 與 copy 兩種安裝，且**只移除本工具建立的項目**——symlink 需指向本 repo、copy 需有對應標記，其餘一律跳過並提示 `--force`。本專案的源文件永遠不會被動到。

```bash
bash uninstall.sh                        # 自動偵測並移除
bash uninstall.sh claude                 # 指定工具
curl -fsSL $BASE/remote-uninstall.sh | bash
```

---

## 支援的 AI 工具

| 工具 | 參數名稱 | 全域路徑 | 專案路徑（`--local`） |
|------|----------|----------|----------|
| Antigravity（CLI 與 IDE） | `antigravity` | `~/.gemini/config/skills/` | `.agents/skills/` |
| Claude Code | `claude` | `~/.claude/skills/` | `.claude/skills/` |
| Codex | `codex` | `~/.codex/skills/` | `.agents/skills/` |
| Cursor | `cursor` | `~/.cursor/skills/` | `.cursor/skills/` |
| GitHub Copilot | `copilot` | `~/.copilot/skills/` | `.github/skills/` |
| OpenCode | `opencode` | `~/.config/opencode/skills/` | `.opencode/skills/` |
| Windsurf | `windsurf` | `~/.codeium/windsurf/skills/` | `.windsurf/skills/` |
| OpenClaw | `openclaw` | `~/.openclaw/skills/` | `.openclaw/skills/` |

CLI 與同品牌的 IDE / extension 共用同一個設定根（Claude Code 用 `~/.claude`，Codex 用 `~/.codex`，Antigravity 用 `~/.gemini/config`），裝一次兩邊都生效。

各工具辨識 skill 的方式不同：Claude Code 用**目錄名**（`git`），Antigravity 用 frontmatter 的 **`name`**（`jpan-git`）。兩者都會載入，但在對話中指名時要用各自的稱呼。

> 參照 [awesome-agent-skills](https://github.com/VoltAgent/awesome-agent-skills)。
> 新增工具或修正路徑請編輯 [`_config.sh`](./_config.sh)，install / uninstall 會自動套用。

---

## 目錄結構

依關注點分離（Separation of Concerns）將技能歸類至不同目錄：

```
agent-skills/
├── skills/
│   ├── git/                  # 版本控制與協作
│   │   ├── SKILL.md          # 分類入口，路由到子技能
│   │   └── conventional-commits/
│   │       └── SKILL.md
│   ├── python/               # 程式語言規範
│   ├── quant/                # 特定業務領域邏輯
│   └── skill-creator/        # 產生技能的 Meta-tool
├── .claude-plugin/           # Plugin / marketplace manifest
├── _config.sh                # AI 工具路徑設定 + 共用邏輯
├── install.sh / uninstall.sh
└── remote-install.sh / remote-uninstall.sh
```

**安裝單位是分類目錄**（`git`、`python`、`quant`…），不是個別子技能。各家 Agent 只掃描一層 `skills/<name>/SKILL.md`，子技能是靠分類入口的 `SKILL.md` 路由載入的；單獨安裝子技能會產生沒有工具會讀取的孤兒目錄。因此 `-s "git/conventional-commits"` 會解析成安裝整個 `git`。

---

## Quant Skills 概覽

量化分析技能集以 pipeline 架構組織，詳見 [入口 SKILL.md](./skills/quant/SKILL.md) 的完整路由表。

| Skill | 定位 |
|-------|------|
| [coding-standards](./skills/quant/coding-standards/SKILL.md) | 跨層通用規範：前視偏誤、IS/OOS 切分、數值穩定性 |
| [data-preprocessing](./skills/quant/data-preprocessing/SKILL.md) | 資料清洗、缺失值、去極值、標準化、跨頻率對齊 |
| [strategy-construction](./skills/quant/strategy-construction/SKILL.md) | 通用策略設計原則 + 截面選股的信號組合與權重分配 |
| [risk-management](./skills/quant/risk-management/SKILL.md) | VaR/CVaR、曝險控制、槓桿、回撤保護、壓力測試 |
| [execution-simulation](./skills/quant/execution-simulation/SKILL.md) | 滑價、漲跌停、市場衝擊、做空成本、結算 |
| [performance-evaluation](./skills/quant/performance-evaluation/SKILL.md) | Sharpe/MDD/Sortino 陷阱、因子評價、換手率分析 |
| [multiple-testing](./skills/quant/multiple-testing/SKILL.md) | FDR 校正、Haircut Sharpe、Placebo Test、實驗日誌 |
| [regime-analysis](./skills/quant/regime-analysis/SKILL.md) | Regime 分類、結構性斷裂偵測、循環論證防護 |

---

## 新增 Skill 的 SOP

1. 在對應分類下建立目錄（如 `skills/python/new-skill/`）。
2. 建立 `SKILL.md`，必須包含 YAML frontmatter：
   ```yaml
   ---
   name: skill-name
   description: 清楚描述 AI 在什麼情境應該啟用這個 skill
   ---
   ```
3. 若新增的是**分類目錄**，執行 `bash install.sh` 建立連結；新增**子技能**則不需要，symlink 模式下源文件更新會即時生效。
4. 開新對話測試 AI 是否正確載入。

> `--copy` 模式與遠端安裝是獨立副本，不會自動同步，任何內容更新後都要重跑安裝指令。
