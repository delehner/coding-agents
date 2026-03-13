#!/bin/bash
# Git utilities for the pipeline.

clone_or_prepare_repo() {
  local repo_url="$1"
  local workdir="$2"
  local base_branch="${3:-main}"

  if [ -d "$workdir/.git" ]; then
    log "INFO" "Repository already exists at $workdir, fetching latest..."
    cd "$workdir" || exit 1
    git fetch origin
    git checkout "$base_branch" 2>/dev/null || true
    git pull origin "$base_branch" 2>/dev/null || true
  else
    log "INFO" "Cloning $repo_url into $workdir..."
    mkdir -p "$(dirname "$workdir")"
    git clone "$repo_url" "$workdir" 2>&1 || {
      # If clone fails (e.g., repo doesn't exist yet), init a new repo
      log "WARN" "Clone failed — initializing new local repository"
      mkdir -p "$workdir"
      cd "$workdir" || exit 1
      git init
      git remote add origin "$repo_url"
      git checkout -b "$base_branch"
      return
    }
    cd "$workdir" || exit 1

    # Handle empty repos (no commits yet, no branches)
    if ! git rev-parse HEAD &>/dev/null; then
      log "INFO" "Empty repository detected — initializing branch $base_branch"
      git checkout -b "$base_branch"
    else
      git checkout "$base_branch" 2>/dev/null || git checkout -b "$base_branch"
    fi
  fi
}

create_feature_branch() {
  local workdir="$1"
  local branch_name="$2"

  cd "$workdir" || exit 1

  if git show-ref --verify --quiet "refs/heads/$branch_name"; then
    log "INFO" "Branch $branch_name already exists, checking out..."
    git checkout "$branch_name"
  else
    log "INFO" "Creating branch $branch_name..."
    git checkout -b "$branch_name"
  fi
}

generate_branch_name() {
  local prd_file="$1"
  local prd_slug

  prd_slug=$(grep '^# ' "$prd_file" 2>/dev/null | head -1 | sed 's/^# //' | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-//' | sed 's/-$//' | cut -c1-50)

  if [ -z "$prd_slug" ]; then
    prd_slug=$(basename "$prd_file" .md | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g')
  fi

  local date_stamp
  date_stamp=$(date +%Y%m%d)
  echo "agent/${prd_slug}-${date_stamp}"
}

create_pull_request() {
  local workdir="$1"
  local base_branch="$2"
  local prd_slug="$3"
  local pr_description_file="$workdir/docs/architecture/$prd_slug/pr-description.md"

  cd "$workdir" || exit 1

  git push -u origin HEAD

  local pr_title
  pr_title=$(head -1 "$pr_description_file" 2>/dev/null | sed 's/^## //' || echo "feat: $prd_slug")

  local pr_body=""
  if [ -f "$pr_description_file" ]; then
    pr_body=$(cat "$pr_description_file")
  else
    pr_body="Automated PR created by Coding Agents Pipeline.\n\nSee docs/architecture/$prd_slug/ for details."
  fi

  gh pr create \
    --base "$base_branch" \
    --title "$pr_title" \
    --body "$pr_body"
}
