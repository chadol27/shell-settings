check_shell_settings_update() {
  local repo="$HOME/shell-settings"
  local upstream counts ahead behind
  local -a messages

  if [[ ! -d "$repo/.git" ]]; then
    print -u2 -- "[shell-settings] Git repository not found: $repo"
    return 1
  fi

  if ! command git -C "$repo" fetch --quiet; then
    print -u2 -- "[shell-settings] Failed to fetch remote changes"
    return 1
  fi

  if [[ -n "$(command git -C "$repo" status --porcelain)" ]]; then
    messages+=("Uncommitted local changes found")
  fi

  upstream="$(command git -C "$repo" rev-parse --abbrev-ref '@{upstream}' 2>/dev/null)"
  if [[ -z "$upstream" ]]; then
    messages+=("No upstream is configured for the current branch")
  else
    counts="$(command git -C "$repo" rev-list --left-right --count "HEAD...$upstream")" || return 1
    read -r ahead behind <<< "$counts"

    if (( ahead > 0 && behind > 0 )); then
      messages+=("Branch has diverged from $upstream (local +$ahead, remote +$behind)")
    elif (( ahead > 0 )); then
      messages+=("Local branch is $ahead commit(s) ahead of $upstream")
    elif (( behind > 0 )); then
      messages+=("Remote $upstream has $behind new commit(s)")
    fi
  fi

  if (( ${#messages[@]} > 0 )); then
    print -- "[shell-settings] Updates require attention"
    printf '  - %s\n' "${messages[@]}"
  fi
}
