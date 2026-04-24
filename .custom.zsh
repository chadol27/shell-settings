# =========================
# System / Info
# =========================

fs() {
  du -ah -d 1 -- "${1:-.}" | sort -h
}

alias ss='watch sensors'

motd() {
  neofetch
  run-parts /etc/update-motd.d 
}


# =========================
# Navigation / Listing
# =========================

alias ll='ls -ahlF'
alias la='ls -A'
alias l='ls -CF'


# =========================
# Shell Utilities
# =========================

alias c='clear'
alias cc='clear'
alias ccc='clear'

alias s='sudo -E'
alias zr='source ~/.zshrc'
alias help='run-help'


# =========================
# Git
# =========================

easygit() {
  local msg
  msg="${1:-$(date +%y%m%d-%H%M%S)}"

  printf '[1/3] git add . ...\n'
  if git add .; then
    printf '  -> add succeeded\n'
  else
    printf '  -> add failed\n' >&2
    return 1
  fi

  if git diff --cached --quiet; then
    printf '[2/3] git commit ... skipped (nothing to commit)\n'
    printf '[3/3] git push ... skipped\n'
    return 0
  fi

  printf '[2/3] git commit -m "%s" ...\n' "$msg"
  if git commit -m "$msg"; then
    printf '  -> commit succeeded\n'
  else
    printf '  -> commit failed\n' >&2
    return 1
  fi

  local push_output push_status

  printf '[3/3] git push ...\n'
  push_output="$(git push 2>&1)"
  push_status=$?

  if [[ -n "$push_output" ]]; then
    printf '%s\n' "$push_output"
  fi

  if (( push_status == 0 )); then
    printf '  -> push succeeded\n'
    printf 'easygit: all steps succeeded\n'
  elif [[ "$push_output" == *"No configured push destination."* ]]; then
    printf '  -> push skipped (no configured push destination)\n'
    printf 'easygit: all steps succeeded\n'
  else
    printf '  -> push failed\n' >&2
    return 1
  fi
}


# =========================
# Docker
# =========================

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


# =========================
# APT
# =========================

alias aud='sudo apt update'
alias alu='sudo apt list --upgradeable'
alias aug='sudo apt upgrade -y'


# =========================
# Python Virtualenv
# =========================

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
