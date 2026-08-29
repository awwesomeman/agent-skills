#!/usr/bin/env bash
# _config.sh — Shared AI Tools configuration for install.sh and uninstall.sh.
# Source this file; do not execute directly.

# Single Source of Truth (SSOT) for AI agents configuration.
# Each entry is formatted as: "arg|name|base_path|local_path"
# target_path is dynamically generated as "$base_path/skills" for all tools.
# Add, remove, or modify AI agents here.
AI_TOOLS_CONFIGS=(
  "antigravity|Antigravity|$HOME/.gemini/config|.agents/skills"
  "claude|Claude Code|$HOME/.claude|.claude/skills"
  "codex|Codex|$HOME/.codex|.agents/skills"
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

# Directory (relative to a target base) holding one ownership marker per copied
# skill. Kept beside the skills, never inside them, so agents never scan it.
MARKER_DIR=".agent-skills"

# Populate ALL_SKILLS with every installable skill under "$1/skills".
#
# A skill is a directory containing SKILL.md. Only the outermost one of a nested
# chain is installable: agents scan a single level, so skills/git/conventional-commits
# is reachable only through the router in skills/git/SKILL.md, and installing it
# separately would produce a directory no tool ever loads. Sorted output puts an
# ancestor before its descendants, so tracking accepted prefixes is enough.
discover_skills() {
  local repo_root="$1"
  local skill_file skill_dir accepted keep

  ALL_SKILLS=()
  while IFS= read -r skill_file; do
    skill_dir="${skill_file#skills/}"
    skill_dir="${skill_dir%/SKILL.md}"
    keep=true
    for accepted in ${ALL_SKILLS[@]+"${ALL_SKILLS[@]}"}; do
      if [[ "$skill_dir" == "$accepted/"* ]]; then
        keep=false
        break
      fi
    done
    [ "$keep" = true ] && ALL_SKILLS+=("$skill_dir")
  done < <(cd "$repo_root" && find skills -mindepth 1 -name "SKILL.md" -type f | sort)
}

# Populate SKILLS with the entries of ALL_SKILLS selected by the comma-separated
# names in SELECTED_SKILLS (all of them when the selection is empty). A selector
# may name a skill or anything inside it, so "git" and "git/conventional-commits"
# both select the installable skill "git".
filter_skills() {
  local found target
  SKILLS=()
  if [ ${#SELECTED_SKILLS[@]} -eq 0 ]; then
    SKILLS=(${ALL_SKILLS[@]+"${ALL_SKILLS[@]}"})
    return
  fi
  for found in ${ALL_SKILLS[@]+"${ALL_SKILLS[@]}"}; do
    for target in "${SELECTED_SKILLS[@]}"; do
      if [[ "$found" == "$target" || "$target" == "$found/"* ]]; then
        SKILLS+=("$found")
        break
      fi
    done
  done
}
