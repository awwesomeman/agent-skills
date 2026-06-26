# agent-skills

跨 Agent 使用的 AI Skills 統一管理專案。

**Single Source of Truth** — 在這裡修改 skill，所有 AI 工具自動同步。

## 目錄

- [安裝與解除安裝](#安裝與解除安裝)
- [目錄結構](#目錄結構)
- [支援的 AI 工具](#支援的-ai-工具)
- [Quant Skills 概覽](#quant-skills-概覽)
- [新增 Skill 的 SOP](#新增-skill-的-sop)
- [更新技巧](#更新技巧)
- [解除安裝](#解除安裝)

---

## 安裝與解除安裝

### 取得專案

```bash
git clone https://github.com/your-org/agent-skills.git
cd agent-skills
```

> 建議 clone 到固定位置（如 `~/agent-skills`），因為 install 腳本會建立 symlink 指向此目錄。移動或刪除源目錄會導致所有 AI 工具的 skill 失效。

```
Usage: bash install.sh [OPTIONS] [AI_TOOLS...]
```

| 參數 | 縮寫 | 說明 | 預設 |
|------|------|------|------|
| `--skills <list>` | `-s` | 指定要安裝的技能分類，逗號分隔，支援前綴比對 | 全部技能 |
| `--local` | `-l` | 將技能安裝到「執行這行指令所在的目錄」內（如專案根目錄下的 `.cursor/skills/` 等），而非全域安裝 | 全域路徑 |
| `--copy` | `-c` | 複製實際檔案取代 symlink，適用於無法保留 clone 的情境 | symlink |
| `--force` | `-f` | `install`：強制覆蓋既有目錄；`uninstall`：強制移除非本工具管理路徑（預設 TTY 互動確認） | 略過 |
| `--path <dir>` | `-p` | 直接安裝到指定目錄（跳過 AI 工具偵測，覆蓋預設路徑） | 自動偵測 |
| `--yes` | `-y` | （僅 `uninstall.sh`）搭配 `--force` 跳過互動確認，適用於 pipe/非互動情境 | 需互動確認 |
| `[AI_TOOLS...]` | — | 指定目標 AI 工具（位置參數，可多個） | 自動偵測已安裝的工具 |

支援的 AI 工具名稱：`antigravity-cli`, `antigravity-ide`, `claude`, `codex`, `cursor`, `copilot`, `opencode`, `windsurf`, `openclaw`。

> 指定工具名稱（位置參數）時只會安裝到「已安裝」的工具；若該工具未安裝會印 `[WARN] ... 未安裝，略過`。要寫入任意目錄請改用 `--path`。

### 常用指令

```bash
# 全域安裝全部技能到所有「已安裝」的 AI 工具（自動偵測）
bash install.sh

# 只安裝到指定工具（可多個）
bash install.sh claude cursor

# 只安裝特定技能分類（逗號分隔，支援前綴比對）
bash install.sh -s "python,git"

# 安裝到目前專案目錄下（.claude/skills、.cursor/skills ...）
bash install.sh --local

# 直接安裝到任意自定義目錄（跳過 AI 工具偵測，全新目錄也可）
bash install.sh --path ~/my-agent/skills

# 用複製取代 symlink（無法保留 clone 的情境）
bash install.sh --copy

# 遠端安裝免 clone（預設 copy 模式）
curl -fsSL https://raw.githubusercontent.com/awwesomeman/agent-skills/main/remote-install.sh | bash
curl -fsSL https://raw.githubusercontent.com/awwesomeman/agent-skills/main/remote-install.sh | bash -s -- -s "python,git" cursor claude

# 解除安裝（用法與 install 對稱）
bash uninstall.sh                       # 自動偵測並移除
bash uninstall.sh claude                # 指定工具
bash uninstall.sh --path ~/my-agent/skills
```

### 調用語法對照表

遠端指令格式（四個「遠端」欄位共用，表格內只列 `-s --` 之後要傳的參數）：

- 遠端 install：`curl -fsSL <BASE>/remote-install.sh | bash [-s -- <參數>]`
- 遠端 uninstall：`curl -fsSL <BASE>/remote-uninstall.sh | bash [-s -- <參數>]`
- `<BASE>` = `https://raw.githubusercontent.com/awwesomeman/agent-skills/main`
- `*` 代表無需額外參數（直接 `| bash`，不用 `-s --`）

| 需求場景 | 地端 install | 遠端 install | 地端 uninstall | 遠端 uninstall |
| :--- | :--- | :--- | :--- | :--- |
| **基本（全域，全部技能）** | `bash install.sh` | `*` | `bash uninstall.sh` | `*` |
| **指定 AI 工具** | `bash install.sh cursor` | `cursor` | `bash uninstall.sh cursor` | `cursor` |
| **指定技能分類** | `bash install.sh -s "python,git"` | `-s "python,git"` | `bash uninstall.sh -s "quant"` | `-s "quant"` |
| **本地專案路徑** | `bash install.sh --local` | `--local` | `bash uninstall.sh --local` | `--local` |
| **自定義目標路徑** | `bash install.sh --path "/p"` | `--path "/p"` | `bash uninstall.sh --path "/p"` | `--path "/p"` |
| **強制覆蓋／移除既有項** | `bash install.sh --force` | `--force` | `bash uninstall.sh --force` | `--force --yes` |
| **複製模式（非 symlink）** | `bash install.sh --copy` | （遠端預設即 copy） | — | — |
| **組合用例** | `bash install.sh -f -s "git" cursor` | `-f -s "git" cursor` | `bash uninstall.sh -s "git" cursor` | `-s "git" cursor` |

**必讀注意**

- **`-s --` 分隔符**：`curl | bash` 傳參時必須使用 `-s --` 引導，否則 `| bash "claude"` 會被 Bash 當成要執行系統上的 `claude`，噴 `syntax error near unexpected token`。
- **預設模式差異**：地端 install 預設 symlink、遠端 install 自動 `--copy`（因此遠端更新技能後需重跑）。uninstall 自動辨識兩種，無差異。
- **`--force` 風險**：會 `rm -rf` 同名目錄（含非本工具建立者）。`uninstall --force` 預設走 TTY 互動確認；`curl | bash` 無 TTY，需再加 `--yes` 才會執行。
- **參數覆蓋順序**：`--path` 同時蓋過 `--local` 與位置參數（腳本會印 `[WARN]`）；指定 `--path` 時不會偵測已安裝的 AI 工具，可直接寫入任意目錄。
- **Fork 自用**：`GITHUB_REPO=user/repo curl -fsSL <BASE>/remote-install.sh | bash` 切換到自己的 repo。

---

## 目錄結構

我們採用依賴關注點分離（Separation of Concerns）的設計，將技能歸類至不同的目錄：

```
agent-skills/
├── skills/                           
│   ├── git/                          # 版本控制與協作 (如 conventional-commits)
│   ├── python/                       # 程式語言規範 (如 coding-standards)
│   ├── quant/                        # 特定業務領域邏輯 (如回測、資料預處理)
│   ├── skill-creator/                # 產生技能的 Meta-tool
│   └── (其他分類...)                 
│       ├── [技能名稱]/
│       │   ├── SKILL.md              # 主文件（必要存在，AI 載入點）
│       │   └── (其他關聯參考文件)
├── install.sh                        # 安裝腳本（symlink 或 copy）
├── uninstall.sh                      # 移除腳本（自動偵測 symlink 與 copy）
├── remote-install.sh                 # 遠端安裝腳本（免 clone，curl | bash）
├── remote-uninstall.sh               # 遠端移除腳本（免 clone，curl | bash）
└── README.md
```

---

## 支援的 AI 工具

| 工具 | 本地路徑 | 全域路徑 |
|------|----------|----------|
| Antigravity CLI | `.agents/skills/` | `~/.gemini/antigravity-cli/skills/` |
| Antigravity IDE | `.agent/skills/` | `~/.gemini/antigravity-ide/skills/`（亦會掃描 `~/.agent/skills/`） |
| Claude Code | `.claude/skills/` | `~/.claude/skills/` |
| Codex | `.agents/skills/` | `~/.agents/skills/` |
| Cursor | `.cursor/skills/` | `~/.cursor/skills/` |
| GitHub Copilot | `.github/skills/` | `~/.copilot/skills/` |
| OpenCode | `.opencode/skills/` | `~/.config/opencode/skills/` |
| Windsurf | `.windsurf/skills/` | `~/.codeium/windsurf/skills/` |
| OpenClaw | `.openclaw/skills/` | `~/.openclaw/skills/` |

> 參照 [awesome-agent-skills](https://github.com/VoltAgent/awesome-agent-skills)
> 如需新增工具或修正安裝路徑，請編輯 [`_config.sh`](./_config.sh)，install / uninstall 腳本會自動套用。

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

1. 在 `skills/` 下的對應分類中建立新目錄（如 `skills/python/new-skill/`）
2. 建立 `SKILL.md`，必須包含 YAML frontmatter：
   ```yaml
   ---
   name: skill-name
   description: 一段清楚的描述，說明 AI 在什麼情境應該啟用這個 skill
   ---
   ```
3. 執行 `bash install.sh` 更新 symlink
4. 開始一個新對話測試 AI 是否正確載入 skill

---

## 更新技巧

使用 **symlink 模式**（預設）修改任何 `SKILL.md` 後，**不需要重新執行 `install.sh`**——symlink 指向的是目錄，源文件更新後所有 Agent 裡的設定會即時生效。只有在**新增或刪除 skill 目錄**時才需要重新執行 `install.sh`。

使用 **`--copy` 模式或遠端安裝**的使用者，更新技能內容後需要**重新執行安裝指令**，因為檔案是獨立副本，不會自動同步。

---

## 解除安裝

指令參見上方 [調用語法對照表](#調用語法對照表) 的「地端 uninstall」／「遠端 uninstall」欄位。`uninstall.sh` / `remote-uninstall.sh` 會自動辨識 symlink 與 copy 兩種安裝，皆不會動到本專案的源文件。
