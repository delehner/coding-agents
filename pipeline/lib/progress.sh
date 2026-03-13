#!/bin/bash
# Progress tracking utilities for agent Ralph Loops.

PROGRESS_DIR=".agent-progress"

init_progress_dir() {
  local workdir="$1"
  mkdir -p "$workdir/$PROGRESS_DIR"
}

get_agent_status() {
  local workdir="$1"
  local agent="$2"
  local progress_file="$workdir/$PROGRESS_DIR/$agent.md"

  if [ ! -f "$progress_file" ]; then
    echo "NOT_STARTED"
    return
  fi

  local status
  status=$(grep '## Status:' "$progress_file" 2>/dev/null | head -1 | sed 's/.*## Status:[[:space:]]*//' | xargs || echo "UNKNOWN")
  echo "$status"
}

is_agent_completed() {
  local workdir="$1"
  local agent="$2"
  [ "$(get_agent_status "$workdir" "$agent")" = "COMPLETED" ]
}

get_all_progress() {
  local workdir="$1"
  local output=""

  for progress_file in "$workdir/$PROGRESS_DIR"/*.md; do
    if [ -f "$progress_file" ]; then
      local agent_name
      agent_name=$(basename "$progress_file" .md)
      output+="=== $agent_name ===\n"
      output+="$(cat "$progress_file")\n\n"
    fi
  done

  echo -e "$output"
}

get_previous_agents_context() {
  local workdir="$1"
  shift
  local agents=("$@")
  local context=""

  for agent in "${agents[@]}"; do
    local progress_file="$workdir/$PROGRESS_DIR/$agent.md"
    if [ -f "$progress_file" ]; then
      context+="## Prior Agent Output: $agent\n"
      context+="$(cat "$progress_file")\n\n"
    fi
  done

  echo -e "$context"
}
