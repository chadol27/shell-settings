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

source $HOME/.custom.zsh


export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

export PATH="$HOME/.local/bin:$PATH"

export COMPOSE_BAKE=true

if [[ -f "$HOME/.local.zsh" ]]; then
  source "$HOME/.local.zsh"
fi

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
alias help='run-help'


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
