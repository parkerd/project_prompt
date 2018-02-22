#!/usr/bin/env bash

# disable python virtualenv prompt
export VIRTUAL_ENV_DISABLE_PROMPT=1

# functions
__pp_complete() {
  project_list="$(ls -1 "$PROJECTS")"
  for sub in ${SUBPROJECTS[*]}; do
    if [[ ! -d $PROJECTS/$sub ]]; then
      mkdir -p $PROJECTS/$sub
    fi
    subprojects=$(ls -1 $PROJECTS/$sub | sed "s/^/$sub\//")
    project_list="$project_list\n$subprojects"
  done
  echo -e "$project_list"
}

__pp_pwd() {
  if [[ -n "$__pp_dir" ]]; then
    pwd | sed "s/$(echo $__pp_dir | sed 's/\//\\\//g')//"
  fi
}

__pp_pwd_clean() {
  if [[ -n "$__pp_dir" ]]; then
    echo $(__pp_pwd | sed 's/^\///')
  elif [[ -n "$BASH_VERSION" ]]; then
    echo "\w"
  else
    echo "%~"
  fi
}

__pp_help() {
  project_base=$(basename $PROJECTS)
  echo "$project_base:"
  ls $PROJECTS
  echo

  for sub in ${SUBPROJECTS[*]}; do
    echo "$project_base/$(basename $sub):"
    ls $PROJECTS/$sub
    echo
  done
}

__pp_workon() {
  # return help if no project given
  if [[ $# -ne 1 ]]; then
    __pp_help
    return
  fi

  __pp_backup_dir=$__pp_dir
  __pp_backup_base=$_pp_base
  # accept local directory as project
  if [[ "$1" == "." ]]; then
    __pp_name=$(basename $(pwd))
    __pp_dir=$(pwd)
  else
    __pp_name=$1
    __pp_dir=$PROJECTS/$__pp_name
    # resolve symlinks
    if [[ -L $__pp_dir ]]; then
      __pp_dir=$(readlink -f $__pp_dir)
    fi
    __pp_base=$__pp_dir
  fi

  # create new projects
  if [[ ! -d $__pp_dir ]]; then
    # zsh immediately exits on ctrl+c
    # unset variables and restore after prompt
    local base=$__pp_base && unset __pp_base
    local dir=$__pp_dir && unset __pp_dir
    local name=$__pp_name && unset __pp_name

    local create_prompt="Create new project '$name'? "
    if [[ -n "$BASH_VERSION" ]]; then
      read -n1 -p "$create_prompt"
    elif [[ -n "$ZSH_VERSION" ]]; then
      read -q "REPLY?$create_prompt"
    fi
    echo

    if [[ "$REPLY" != "y" ]]; then
      return
    fi

    __pp_dir=$dir
    __pp_name=$name
    mkdir -p $__pp_dir && git init $__pp_dir >/dev/null
  fi

  if [[ -n "$_PS1" ]]; then
    # reset prompt if previously in project
    export PS1=$_PS1
  else
    # save prompt for exit
    export _PS1=$PS1
  fi

  # strip pwd from prompt
  local ps1_pwd
  if [[ -n "$BASH_VERSION" ]]; then
    ps1_pwd="\w"
  elif [[ -n "$ZSH_VERSION" ]]; then
    ps1_pwd="%~"
  fi

  # change directory
  cd $__pp_dir

  # replace prompt
  __pp_ps1_tail=$(echo "$PS1" | sed "s/\\$ps1_pwd//")
  if [[ -d ".git" ]]; then
    export PS1='($(__pp_git_branch)|$__pp_name)$(__pp_pwd)'"$__pp_ps1_tail"
  elif [[ -d ".hg" ]]; then
    export PS1='($(__pp_hg_status)$__pp_name)$(__pp_pwd)'"$__pp_ps1_tail"
  else
    export PS1='[$__pp_name]$(__pp_pwd)'"$__pp_ps1_tail"
  fi

  alias cd='__pp_cd'
  alias cdd='__pp_quit'
}

__pp_git_branch() {
  # Support subrepos
  if [[ -z "$__pp_dir" ]]; then
    return
  elif [[ -d ".git" ]]; then
    git_status=$(git status 2>/dev/null)
  else
    git_status=$(cd $__pp_dir && git status 2>/dev/null)
  fi

  if [[ $? -eq 0 ]]; then
    branch=$(echo "$git_status" | head -1 | cut -d' ' -f4-)
    if [[ "$branch" == "" ]]; then
      branch=$(echo "$git_status" | head -1 | cut -d' ' -f3-)
    fi

    branch=" ${branch}"

    if [[ $(echo "$git_status" | egrep -c "Untracked|Change") -gt 0 ]]; then
      branch="${branch} ±"
    fi

    echo $branch
  fi
}

__pp_hg_status() {
  if [[ $(cd $__pp_dir && hg status | grep -c "^") -gt 0 ]]; then
    echo "*|"
  fi
}

__pp_cd() {
  if [[ -z "$@" ]]; then
    cd $__pp_dir
  else
    if [[ -d "$@" ]]; then
      cd "$@"
    else
      echo "cd: no such file or directory: ${@}" 1>&2
    fi
  fi
}

__pp_quit() {
  alias cd &>/dev/null && unalias cd
  alias cdd &>/dev/null && unalias cdd
  unset __pp_name
  unset __pp_dir
  unset __pp_base

  cd
  export PS1=$_PS1
  if [[ -n "$_PATH" ]]; then
    export PATH=$_PATH
  fi
}

# alias
alias workon='__pp_workon'

# autocomplete
if [[ -d $PROJECTS ]]; then
  if [[ -n "$BASH_VERSION" ]]; then
    complete -W "$(__pp_complete)" workon
  elif [[ -n "$ZSH_VERSION" ]]; then
    __pp_zsh() {
      reply=($(__pp_complete))
    }
    compctl -K __pp_zsh __pp_workon
  fi
fi
