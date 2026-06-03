#!/usr/bin/env bash
# _config.sh — Shared AI Tools configuration for install.sh and uninstall.sh.
# Source this file; do not execute directly.

# Single Source of Truth (SSOT) for AI agents configuration.
# Each entry is formatted as: "arg|name|base_path|local_path"
# target_path is dynamically generated as "$base_path/skills" for all tools.
# Add, remove, or modify AI agents here.
AI_TOOLS_CONFIGS=(
  "antigravity-cli|Antigravity CLI|$HOME/.gemini/antigravity-cli|.agents/skills"
  "antigravity-ide|Antigravity IDE|$HOME/.gemini/antigravity|.agent/skills"
  "claude|Claude Code|$HOME/.claude|.claude/skills"
  "codex|Codex|$HOME/.agents|.agents/skills"
  "cursor|Cursor|$HOME/.cursor|.cursor/skills"
  "copilot|GitHub Copilot|$HOME/.copilot|.github/skills"
  "opencode|OpenCode|$HOME/.config/opencode|.opencode/skills"
  "windsurf|Windsurf|$HOME/.codeium/windsurf|.windsurf/skills"
  "openclaw|OpenClaw|$HOME/.openclaw|.openclaw/skills"
)

# Parse the configs and populate parallel arrays for backward compatibility.
_init_config() {
  local config arg name base local_path
  local old_ifs="$IFS"

  AI_TOOLS_NAMES=()
  AI_TOOLS_BASES=()
  AI_TOOLS_PATHS=()
  AI_TOOLS_LOCAL_PATHS=()
  AI_TOOLS_ARGS=()

  for config in "${AI_TOOLS_CONFIGS[@]}"; do
    IFS='|' read -r arg name base local_path <<< "$config"
    AI_TOOLS_ARGS+=("$arg")
    AI_TOOLS_NAMES+=("$name")
    AI_TOOLS_BASES+=("$base")
    AI_TOOLS_PATHS+=("$base/skills")
    AI_TOOLS_LOCAL_PATHS+=("$local_path")
  done

  IFS="$old_ifs"
}

_init_config
unset -f _init_config
