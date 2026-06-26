#!/usr/bin/env bash
# uninstall.sh — Remove symlinks and copied skills created by install.sh.
# Usage: bash uninstall.sh [--local] [--force] [--yes] [--path DIR] [--skills "git,python,quant"] [AI_TOOLS...]
# Does NOT delete source files in this repository.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")" && pwd)"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# shellcheck source=_config.sh
source "$REPO_ROOT/_config.sh"

confirm_force_remove() {
  local path="$1"
  if [ "$ASSUME_YES" = true ]; then
    return 0
  fi
  # The /dev/tty device node almost always exists, so -e does not prove a usable
  # controlling terminal (cron/systemd/ssh -T etc. fail to open it). Probe readability instead.
  if ! { : < /dev/tty; } 2>/dev/null; then
    echo -e "${RED}[ABORT] --force on unmanaged path requires a TTY for confirmation: $path${NC}"
    echo -e "${RED}        Re-run with --yes to skip interactive confirmation (dangerous).${NC}"
    return 1
  fi
  local reply=""
  echo -e "${RED}[CONFIRM] About to rm -rf unmanaged path: $path${NC}" >&2
  read -r -p "Type 'yes' to delete, anything else to skip: " reply < /dev/tty
  [ "$reply" = "yes" ]
}

remove_skill() {
  local path="$1"
  local source_path="$2"

  # Safety: only protect when target is a real directory (not a symlink) whose
  # absolute path equals source. symlinks must stay removable (otherwise symlinks
  # created by install cannot be uninstalled), so exclude -L; check -L before -d
  # to avoid misclassifying a symlink-to-dir.
  if [ -n "$source_path" ] && [ ! -L "$path" ] && [ -d "$path" ] && [ -d "$source_path" ]; then
    local real_source real_target
    real_source="$(cd -P "$source_path" 2>/dev/null && pwd || true)"
    real_target="$(cd -P "$path" 2>/dev/null && pwd || true)"
    if [ -n "$real_source" ] && [ "$real_source" = "$real_target" ]; then
      echo -e "${YELLOW}[SKIP] Target resolves to source, refusing to delete: $path${NC}"
      return
    fi
  fi

  if [ -L "$path" ]; then
    rm "$path"
    echo -e "${GREEN}Removed symlink: $path${NC}"
  elif [ -d "$path" ] && [ -f "$path/.installed-by-agent-skills" ]; then
    rm -rf "$path"
    echo -e "${GREEN}Removed copied skill: $path${NC}"
  elif [ -e "$path" ]; then
    if [ "$USE_FORCE" = true ]; then
      if confirm_force_remove "$path"; then
        rm -rf "$path"
        echo -e "${YELLOW}[INFO] Forced removal of unmanaged path: $path${NC}"
      else
        echo -e "${YELLOW}[SKIP] Kept unmanaged path: $path${NC}"
      fi
    else
      echo -e "${RED}Not managed by agent-skills, skipping: $path (use --force to remove)${NC}"
    fi
  fi
}

echo "Dynamically uninstalling skills..."
echo ""

# Parse arguments
SELECTED_SKILLS=()
EXPLICIT_TARGETS=()
USE_LOCAL=false
USE_FORCE=false
CUSTOM_PATH=""
ASSUME_YES=false

while [[ $# -gt 0 ]]; do
  case $1 in
    -l|--local)
      USE_LOCAL=true
      shift
      ;;
    -f|--force)
      USE_FORCE=true
      shift
      ;;
    -y|--yes)
      ASSUME_YES=true
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
        CUSTOM_PATH="$2"
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
ALL_SKILLS=()
while IFS= read -r skill_file; do
  skill_dir="${skill_file#skills/}"
  skill_dir="${skill_dir%/SKILL.md}"
  ALL_SKILLS+=("$skill_dir")
done < <(cd "$REPO_ROOT" && find skills -mindepth 1 -name "SKILL.md" -type f | sort)

if [ ${#ALL_SKILLS[@]} -eq 0 ]; then
  echo -e "${YELLOW}[WARN] No skills found in skills/ directory.${NC}"
  exit 0
fi

# Filter skills based on --skills argument
SKILLS=()
if [ ${#SELECTED_SKILLS[@]} -eq 0 ]; then
  SKILLS=("${ALL_SKILLS[@]}")
else
  for found in "${ALL_SKILLS[@]}"; do
    for target in "${SELECTED_SKILLS[@]}"; do
      if [[ "$found" == "$target" || "$found" == "$target/"* ]]; then
        SKILLS+=("$found")
        break
      fi
    done
  done
fi

if [ ${#SKILLS[@]} -eq 0 ]; then
  echo -e "${YELLOW}[WARN] No skills matched the specified --skills filter: ${SELECTED_SKILLS[*]}${NC}"
  exit 0
fi

# Determine which tools to uninstall from
TARGET_INDICES=()

if [ -n "$CUSTOM_PATH" ]; then
  # --path removes straight from the given directory: skip AI-tool auto-detection
  # and --local entirely, so unregistered/custom locations work without pre-setup.
  if [ "$USE_LOCAL" = true ]; then
    echo -e "${YELLOW}[WARN] --path overrides --local; using --path${NC}"
  fi
  if [ ${#EXPLICIT_TARGETS[@]} -gt 0 ]; then
    echo -e "${YELLOW}[WARN] --path ignores positional AI_TOOLS: ${EXPLICIT_TARGETS[*]}${NC}"
  fi
  echo "Removing from custom path: $CUSTOM_PATH"
  TARGET_INDICES+=("manual")
elif [ ${#EXPLICIT_TARGETS[@]} -eq 0 ]; then
  echo "No explicit targets provided. Auto-detecting installed AI tools..."
  for i in "${!AI_TOOLS_NAMES[@]}"; do
    if [ "$USE_LOCAL" = true ]; then
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
        # Same "must be installed" rule as auto-detection: skip a named tool whose
        # base dir is absent (nothing to remove). Use --path for an arbitrary dir.
        if [ "$USE_LOCAL" = true ]; then
          check_base="$(pwd)/${AI_TOOLS_LOCAL_PATHS[$i]%/skills}"
        else
          check_base="${AI_TOOLS_BASES[$i]}"
        fi
        if [ ! -d "$check_base" ]; then
          echo -e "${YELLOW}[WARN] ${AI_TOOLS_NAMES[$i]} not installed, skipping: $check_base${NC}"
          echo -e "${YELLOW}       To remove from a specific dir, use: --path <dir>${NC}"
        else
          TARGET_INDICES+=("$i")
          echo -e "${GREEN}Selected: ${AI_TOOLS_NAMES[$i]}${NC}"
        fi
        break
      fi
    done
    if [ "$found" = false ]; then
      echo -e "${YELLOW}[WARN] Unknown AI tool: $arg (Available: ${AI_TOOLS_ARGS[*]})${NC}"
      echo -e "${YELLOW}       To remove from a custom directory, use: --path <dir>${NC}"
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
  UNINSTALL_ROOT="$(pwd)"
  echo -e "${BLUE}Removing from local paths under: $UNINSTALL_ROOT${NC}"
  echo ""
fi

for i in "${TARGET_INDICES[@]}"; do
  if [ "$i" = "manual" ]; then
    tool="Custom path"
    target_base="$CUSTOM_PATH"
  else
    tool="${AI_TOOLS_NAMES[$i]}"
    if [ "$USE_LOCAL" = true ]; then
      target_base="$UNINSTALL_ROOT/${AI_TOOLS_LOCAL_PATHS[$i]}"
    else
      target_base="${AI_TOOLS_PATHS[$i]}"
    fi
  fi
  echo -e "${BLUE}-- Removing from $tool --${NC}"
  echo "Target: $target_base"

  for skill in "${SKILLS[@]}"; do
    target_path="$target_base/$skill"
    remove_skill "$target_path" "$REPO_ROOT/skills/$skill"

    # Clean up empty parent directories (e.g. if ~/.cursor/skills/git is empty after removal)
    parent_dir="$(dirname "$target_path")"
    if [[ "$parent_dir" != "$target_base" && -d "$parent_dir" ]]; then
      rmdir "$parent_dir" 2>/dev/null || true
    fi
  done
  echo ""
done

echo "Done. Source files in this repository are untouched."
