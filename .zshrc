if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="powerlevel10k/powerlevel10k"

plugins=(
  git
  fzf
  zsh-completions
  fzf-tab
  zsh-autosuggestions
  zsh-syntax-highlighting
)

source $ZSH/oh-my-zsh.sh

[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

export PATH="$HOME/.local/bin:$PATH"

export COMPOSE_BAKE=true

export PNPM_HOME="$HOME/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME/bin:"*) ;;
  *) export PATH="$PNPM_HOME/bin:$PATH" ;;
esac

if [[ -f "$HOME/.local.zsh" ]]; then
  source "$HOME/.local.zsh"
fi


# #########################
# Check for Change/Update
# #########################

check-repo() {
  local repo="${1:-$HOME/.config/shell-settings}"
  local upstream counts ahead behind
  local -a messages

  if [[ ! -d "$repo/.git" ]]; then
    print -u2 -- "[shell-settings] Git repository not found: $repo"
    return 2
  fi

  if ! command git -C "$repo" fetch --quiet; then
    print -u2 -- "[shell-settings] Failed to fetch remote changes"
    return 2
  fi

  if [[ -n "$(command git -C "$repo" status --porcelain)" ]]; then
    messages+=("Uncommitted local changes found")
  fi

  upstream="$(command git -C "$repo" rev-parse --abbrev-ref '@{upstream}' 2>/dev/null)"
  if [[ -z "$upstream" ]]; then
    messages+=("No upstream is configured for the current branch")
  else
    if ! counts="$(command git -C "$repo" rev-list --left-right --count "HEAD...$upstream")"; then
      print -u2 -- "[shell-settings] Failed to compare local and remote branches"
      return 2
    fi
    read -r ahead behind <<< "$counts"

    if (( ahead > 0 && behind > 0 )); then
      messages+=("Branch has diverged from $upstream (local +$ahead, remote +$behind)")
    elif (( ahead > 0 )); then
      messages+=("Local branch is $ahead commit(s) ahead of $upstream")
    elif (( behind > 0 )); then
      if (( ${#messages[@]} == 0 )); then
        if [[ ! -t 0 ]]; then
          print -- "[shell-settings] Remote $upstream has $behind new commit(s); run 'check-repo \"$repo\"' to update"
          return 1
        fi

        local answer
        read -r "answer?Remote $upstream has $behind new commit(s). Pull changes? [Y/n] "
        if [[ "$answer" != [nN] ]]; then
          if ! command git -C "$repo" pull --ff-only; then
            print -u2 -- "[shell-settings] Failed to pull remote changes; continuing without update"
            return 2
          fi
          print -- "[shell-settings] Remote changes pulled successfully"
        fi
        return 0
      fi

      messages+=("Remote $upstream has $behind new commit(s)")
    fi
  fi

  if (( ${#messages[@]} > 0 )); then
    print -- "[shell-settings] Updates require attention"
    printf '  - %s\n' "${messages[@]}"
    return 1
  fi

  return 0
}

check-repo-and-run() {
  if (( $# < 2 )); then
    print -u2 -- "Usage: check-repo-and-run <repopath> <runcommand> [args...]"
    return 2
  fi

  local repo="$1"
  local runcommand="$2"
  shift 2

  check-repo "$repo"
  local repo_status=$?

  if (( repo_status == 1 )); then
    if [[ -t 0 ]]; then
      local answer
      read -q "answer?Updates require attention. Run '$runcommand' anyway? [y/N] "
      print
      [[ "$answer" == [yY] ]] || return 1
    else
      print -u2 -- "[shell-settings] Cannot prompt for confirmation; running '$runcommand' without updating"
    fi
  elif (( repo_status != 0 )); then
    print -u2 -- "[shell-settings] Repository check failed; running '$runcommand' anyway"
  fi

  command "$runcommand" "$@"
}


# Shell settings update check
{ sleep 1; check-repo; } </dev/null >/dev/tty 2>&1 &!


# omz plugins/themes update
function omz-custom-update() {
  local custom="${ZSH_CUSTOM:-$ZSH/custom}"
  local dir
  local failed=0

  for dir in "$custom"/{plugins,themes}/*(N/); do
    # Only update directories that are Git repository roots
    [[ -e "$dir/.git" ]] || continue

    echo "Updating ${dir:t}..."

    if ! git -C "$dir" pull --ff-only; then
      echo "Failed to update: $dir" >&2
      failed=1
    fi
  done

  (( failed )) && return 1
  echo "All custom plugins and themes are up to date."
}


# #########################
# Custom Aliases/Functions
# #########################

# System / Info

fs() {
  du -ah -d 1 -- "${1:-.}" | sort -h
}

alias ss='watch sensors'

motd() {
  run-parts /etc/update-motd.d 
}


# Navigation / Listing

alias ll='ls -ahlF'
alias la='ls -A'
alias l='ls -CF'


# Shell Utilities

alias c='clear'
alias cc='clear'
alias ccc='clear'

alias s='sudo -E'
alias zr='source ~/.zshrc'

help() {
  if (( $# == 0 )); then
    echo "usage: help <command>"
    return 1
  fi

  local cmd="$1"

  # Alias
  if (( ${+aliases[$cmd]} )); then
    echo "$cmd='${aliases[$cmd]}'"

    local -a words
    words=(${(z)aliases[$cmd]})

    [[ -n "$words[1]" ]] && cmd="$words[1]"
  fi

  # Shell function
  if [[ "$(whence -w "$cmd" 2>/dev/null)" == "$cmd: function" ]]; then
    functions "$cmd"
  fi

  # Zsh help
  if whence -w "$cmd" &>/dev/null; then
    run-help "$cmd" 2>/dev/null
  fi

  # man page
  if man -w "$cmd" &>/dev/null; then
    man "$cmd"
  fi
}


# Docker

alias dc='docker compose'

dcat() {
  if [[ -z "$1" ]]; then
    echo "no arg"
    return 1
  fi

  docker compose logs "$1" --tail 200 --timestamps
  docker compose attach "$1" --detach-keys="ctrl-x"
}

run-temp-docker() (
  local image="temp-$(date +%Y%m%d-%H%M%S)-$$"

  cleanup() {
    docker rmi -f "$image" >/dev/null 2>&1
  }

  trap cleanup EXIT INT TERM

  docker build -t "$image" . || return $?

  if [[ -n "$1" ]]; then
    docker run --rm --entrypoint "$1" "$image" "${@:2}"
  else
    docker run --rm "$image"
  fi
)


# APT

_has_cmd() {
  (( $+commands[$1] ))
}

aud() {
  if _has_cmd nala; then
    sudo nala update "$@"
  else
    sudo apt update "$@"
  fi
}

alu() {
  if _has_cmd nala; then
    nala list --upgradable "$@"
  else
    apt list --upgradeable "$@"
  fi
}

aug() {
  if _has_cmd nala; then
    sudo nala upgrade -y --no-update "$@"
  else
    sudo apt upgrade -y "$@"
  fi
}


# Python Virtualenv

a() {
  if [[ -d ./env ]]; then
    source ./env/bin/activate
  elif [[ -d ./venv ]]; then
    source ./venv/bin/activate
  elif [[ -d ./myenv ]]; then
    source ./myenv/bin/activate
  else
    echo "error"
    return 1
  fi
}

alias da='deactivate'


# opencode

export PATH=/home/chadol/.opencode/bin:$PATH
alias opencode='check-repo-and-run "$HOME/.config/opencode" opencode'
