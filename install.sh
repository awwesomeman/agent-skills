#!/usr/bin/env bash
# install.sh — Install skills to AI agent skill directories via symlinks or copy.
# Usage: bash install.sh [--local] [--copy] [--force] [--path DIR] [--skills "git,python,quant"] [AI_TOOLS...]
# Re-run anytime skills are added/renamed to refresh symlinks or copies.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")" && pwd)"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# shellcheck source=_config.sh
source "$REPO_ROOT/_config.sh"

install_skill() {
  local skill_name="$1"
  local target_base="$2"
  local target_path="$target_base/$skill_name"
  local source_path="$REPO_ROOT/skills/$skill_name"
  local marker="$target_base/$MARKER_DIR/$skill_name"

  if [ ! -e "$source_path" ]; then
    echo -e "${YELLOW}[WARN] Skipping $skill_name -- source not found: $source_path${NC}"
    return
  fi

  # Refuse to install a skill over itself (e.g. --path pointing back at skills/),
  # which would delete the source or create a circular link.
  local real_source real_target_parent
  real_source="$(cd -P "$source_path" 2>/dev/null && pwd || true)"
  real_target_parent="$(cd -P "$(dirname "$target_path")" 2>/dev/null && pwd || true)"
  if [ -n "$real_source" ] && [ "$real_source" = "$real_target_parent/$(basename "$target_path")" ]; then
    echo -e "${YELLOW}[SKIP] Target resolves to source, skipping: $target_path${NC}"
    return
  fi

  mkdir -p "$(dirname "$target_path")"

  # Remove existing symlink or handle real directory/file
  if [ -L "$target_path" ]; then
    rm "$target_path"
  elif [ -d "$target_path" ]; then
    if [ -e "$marker" ] || [ -f "$target_path/.installed-by-agent-skills" ] || [ "$USE_FORCE" = true ]; then
      if [ "$USE_FORCE" = true ] && [ ! -e "$marker" ] && [ ! -f "$target_path/.installed-by-agent-skills" ]; then
        echo -e "${YELLOW}[INFO] Forcing overwrite of $target_path${NC}"
      fi
      rm -rf "$target_path"
    elif [ "$USE_COPY" = true ]; then
      echo -e "${YELLOW}[WARN] $target_path exists and is not managed by agent-skills -- skipping (use --force to overwrite)${NC}"
      return
    else
      echo -e "${YELLOW}[WARN] $target_path exists and is not a symlink -- skipping to avoid overwrite (use --force to overwrite)${NC}"
      return
    fi
  elif [ -e "$target_path" ]; then
    echo -e "${YELLOW}[WARN] $target_path exists as a file (expected directory) -- skipping${NC}"
    return
  fi

  if [ "$USE_COPY" = true ]; then
    cp -r "$source_path" "$target_path"
    # A copy carries no trace of its origin, so record ownership beside the skill
    # (never inside it -- agents scan the skill directory). Symlinks need no marker:
    # uninstall proves ownership by reading where they point.
    mkdir -p "$target_base/$MARKER_DIR"
    echo "copy" > "$marker"
    echo -e "${GREEN}[OK] $skill_name (copied)${NC}"
  else
    ln -s "$source_path" "$target_path"
    rm -f "$marker" 2>/dev/null || true
    echo -e "${GREEN}[OK] $skill_name${NC}"
  fi
}

echo "Dynamically installing skills..."
echo ""

# Parse arguments
SELECTED_SKILLS=()
EXPLICIT_TARGETS=()
USE_LOCAL=false
USE_COPY=false
USE_FORCE=false
CUSTOM_PATH=""

while [[ $# -gt 0 ]]; do
  case $1 in
    -l|--local)
      USE_LOCAL=true
      shift
      ;;
    -c|--copy)
      USE_COPY=true
      shift
      ;;
    -f|--force)
      USE_FORCE=true
      shift
      ;;
    -s|--skills)
      if [ -n "${2:-}" ]; then
        IFS=',' read -ra SELECTED_SKILLS <<< "$2"
        shift 2
      else
        echo -e "${YELLOW}[ERROR] --skills requires a comma-separated list of skills${NC}"
        exit 1
      fi
      ;;
    -p|--path)
      if [ -n "${2:-}" ]; then
        # Normalize to an absolute path so the target is unambiguous regardless
        # of where the script is invoked from.
        case "$2" in
          /*) CUSTOM_PATH="$2" ;;
          *) CUSTOM_PATH="$(pwd)/$2" ;;
        esac
        shift 2
      else
        echo -e "${YELLOW}[ERROR] --path requires a directory path${NC}"
        exit 1
      fi
      ;;
    *)
      EXPLICIT_TARGETS+=("$1")
      shift
      ;;
  esac
done

# Find all valid skills
discover_skills "$REPO_ROOT"

if [ ${#ALL_SKILLS[@]} -eq 0 ]; then
  echo -e "${YELLOW}[WARN] No skills found (no SKILL.md files located in skills/ directory).${NC}"
  exit 0
fi

# Filter skills based on --skills argument
filter_skills

if [ ${#SKILLS[@]} -eq 0 ]; then
  echo -e "${YELLOW}[WARN] No skills matched the specified --skills filter: ${SELECTED_SKILLS[*]}${NC}"
  exit 0
fi

# Determine target AI tools
TARGET_INDICES=()

if [ -n "$CUSTOM_PATH" ]; then
  # --path installs straight into the given directory: skip AI-tool auto-detection
  # and --local entirely, so unregistered/custom locations work without pre-setup.
  if [ "$USE_LOCAL" = true ]; then
    echo -e "${YELLOW}[WARN] --path overrides --local; using --path${NC}"
  fi
  if [ ${#EXPLICIT_TARGETS[@]} -gt 0 ]; then
    echo -e "${YELLOW}[WARN] --path ignores positional AI_TOOLS: ${EXPLICIT_TARGETS[*]}${NC}"
  fi
  echo "Installing into custom path: $CUSTOM_PATH"
  TARGET_INDICES+=("manual")
elif [ ${#EXPLICIT_TARGETS[@]} -eq 0 ]; then
  echo "No explicit targets provided. Auto-detecting installed AI tools..."
  for i in "${!AI_TOOLS_NAMES[@]}"; do
    if [ "$USE_LOCAL" = true ]; then
      # An existing base dir (e.g. .cursor) means this tool is in use in the project;
      # show the actual skills dir that will be written so the message matches the target.
      local_base="$(pwd)/${AI_TOOLS_LOCAL_PATHS[$i]%/skills}"
      local_target="$(pwd)/${AI_TOOLS_LOCAL_PATHS[$i]}"
      if [ -d "$local_base" ]; then
        TARGET_INDICES+=("$i")
        echo -e "${GREEN}Found (local): ${AI_TOOLS_NAMES[$i]}${NC} ($local_target)"
      fi
    else
      if [ -d "${AI_TOOLS_BASES[$i]}" ]; then
        TARGET_INDICES+=("$i")
        echo -e "${GREEN}Found: ${AI_TOOLS_NAMES[$i]}${NC} (${AI_TOOLS_PATHS[$i]})"
      fi
    fi
  done
else
  echo "Using specified targets..."
  for arg in "${EXPLICIT_TARGETS[@]}"; do
    arg_lower=$(echo "$arg" | tr '[:upper:]' '[:lower:]')
    found=false
    for i in "${!AI_TOOLS_ARGS[@]}"; do
      if [ "${AI_TOOLS_ARGS[$i]}" = "$arg_lower" ]; then
        found=true
        # Honour the same "must be installed" rule as auto-detection: skip a named
        # tool whose base dir is absent. Use --path to install into an arbitrary dir.
        if [ "$USE_LOCAL" = true ]; then
          check_base="$(pwd)/${AI_TOOLS_LOCAL_PATHS[$i]%/skills}"
        else
          check_base="${AI_TOOLS_BASES[$i]}"
        fi
        if [ ! -d "$check_base" ]; then
          echo -e "${YELLOW}[WARN] ${AI_TOOLS_NAMES[$i]} not installed, skipping: $check_base${NC}"
          echo -e "${YELLOW}       To install there anyway, use: --path <dir>${NC}"
        else
          TARGET_INDICES+=("$i")
          echo -e "${GREEN}Selected: ${AI_TOOLS_NAMES[$i]}${NC}"
        fi
        break
      fi
    done
    if [ "$found" = false ]; then
      echo -e "${YELLOW}[WARN] Unknown AI tool: $arg (Available: ${AI_TOOLS_ARGS[*]})${NC}"
      echo -e "${YELLOW}       To install into a custom directory, use: --path <dir>${NC}"
    fi
  done
fi

echo ""

if [ ${#TARGET_INDICES[@]} -eq 0 ]; then
  echo -e "${YELLOW}[ERROR] No valid AI tools found or specified. Exiting.${NC}"
  echo "Available targets to specify manually: ${AI_TOOLS_ARGS[*]}"
  exit 1
fi

if [ "$USE_LOCAL" = true ] && [ -z "$CUSTOM_PATH" ]; then
  INSTALL_ROOT="$(pwd)"
  echo -e "${BLUE}Installing to local paths under: $INSTALL_ROOT${NC}"
  echo ""
fi

# Two tools can resolve to the same directory (e.g. Antigravity CLI and Codex both
# use .agents/skills under --local); install there once.
PROCESSED_BASES=""
last_target_base=""
for i in "${TARGET_INDICES[@]}"; do
  if [ "$i" = "manual" ]; then
    tool="Custom path"
    target_base="$CUSTOM_PATH"
  else
    tool="${AI_TOOLS_NAMES[$i]}"
    if [ "$USE_LOCAL" = true ]; then
      target_base="$INSTALL_ROOT/${AI_TOOLS_LOCAL_PATHS[$i]}"
    else
      target_base="${AI_TOOLS_PATHS[$i]}"
    fi
  fi
  case "$PROCESSED_BASES" in
    *"|$target_base|"*) continue ;;
  esac
  PROCESSED_BASES="$PROCESSED_BASES|$target_base|"
  last_target_base="$target_base"
  echo -e "${BLUE}-- $tool --${NC}"
  echo "Target: $target_base"

  for skill in "${SKILLS[@]}"; do
    install_skill "$skill" "$target_base"
  done
  echo ""
done

if [ "$USE_COPY" = true ]; then
  echo "Done. All skills copied."
else
  echo "Done. All symlinks installed."
fi
echo ""
echo "To verify: ls -la ${last_target_base}/"
