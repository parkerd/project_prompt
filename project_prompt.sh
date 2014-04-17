#!/usr/bin/env bash
# disable python virtualenv prompt
VIRTUAL_ENV_DISABLE_PROMPT=1

# functions
__pp_complete() {
  project_list="$(ls -1 $PROJECTS)"
  for sub in ${SUBPROJECTS[*]}; do
    subprojects=$(ls -1 $PROJECTS/$sub | sed "s/^/$sub\//")
    project_list="$project_list\n$subprojects"
  done
  echo -e "$project_list"
}

__pp_pwd() {
  pwd | sed "s/$(echo $__pp_dir | sed 's/\//\\\//g')//"
}

__pp_goenv() {
  export _GOPATH=$GOPATH
  export GOPATH=$__pp_dir
  export _PATH=$PATH
  export PATH=$GOPATH/bin:$PATH
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
  if [ $# -ne 1 ]; then
    __pp_help
    return
  fi

  # reset prompt if previously in project
  if [ -n "$_PS1" ]; then
    export PS1=$_PS1
  fi

  # accept local directory as project
  if [[ "$1" == "." ]]; then
    __pp_name=$(basename $(pwd))
    __pp_dir=$(pwd)
  else
    __pp_name=$1
    __pp_dir=$PROJECTS/$__pp_name
  fi

  # shorten prompt for go
  if [[ "${__pp_name:0:3}" == "go/" ]]; then
    __pp_goenv
    __pp_base=$__pp_dir
    if [ -z $GITHUB ]; then
      echo "Set \$GITHUB to ensure proper workspace setup."
      __pp_dir=$__pp_dir/src
    else
      __pp_dir=$__pp_dir/src/$GITHUB/${__pp_name:3}
    fi
  fi

  # create new projects
  if [ ! -d $__pp_dir ]; then
    local create_prompt="Create new project '$__pp_name'? "
    if [ -n "$BASH_VERSION" ]; then
      read -n1 -p "$create_prompt"
    elif [ -n "$ZSH_VERSION" ]; then
      read -q "REPLY?$create_prompt"
    fi
    echo
    if [[ "$REPLY" == "y" ]]; then
      if [[ "${__pp_name:0:3}" == "go/" ]]; then
        mkdir -p $__pp_base/{bin,pkg,src}
      fi
      mkdir -p $__pp_dir && git init $__pp_dir >/dev/null
    else
      return
    fi
  fi

  # save prompt for exit
  if [ -z "$_PS1" ]; then
    export _PS1=$PS1
  fi

  # strip pwd from prompt
  local ps1_pwd
  if [ -n "$BASH_VERSION" ]; then
    ps1_pwd="\w"
  elif [ -n "$ZSH_VERSION" ]; then
    ps1_pwd="%~"
  fi

  # replace prompt
  cd $__pp_dir
  __pp_ps1_tail=$(echo "$PS1" | sed "s/\\$ps1_pwd//")
  if [ -d ".git" ]; then
    export PS1='($(__pp_git_branch)|$__pp_name)$(__pp_pwd)'"$__pp_ps1_tail"
  elif [ -d ".hg" ]; then
    export PS1='($(__pp_hg_status)$__pp_name)$(__pp_pwd)'"$__pp_ps1_tail"
  else
    export PS1='[$__pp_name]$(__pp_pwd)'"$__pp_ps1_tail"
  fi

  alias cd='__pp_cd'
  alias cdd='__pp_quit'
}

__pp_git_branch() {
  git_status=$(cd $__pp_dir && git status)

  branch=$(echo "$git_status" | head -1 | cut -d' ' -f4-)
  if [[ "$branch" == "" ]]; then
    branch=$(echo "$git_status" | head -1 | cut -d' ' -f3-)
  fi

  if [ $(echo "$git_status" | egrep -c "Untracked|Change") -gt 0 ]; then
    echo "${branch}*"
  else
    echo $branch
  fi
}

__pp_hg_status() {
  if [ $(cd $__pp_dir && hg status | grep -c "^") -gt 0 ]; then
    echo "*|"
  fi
}

__pp_cd() {
  if [ -z "$@" ]; then
    cd $__pp_dir
  else
    cd "$@"
  fi
}

__pp_quit() {
  unalias cd
  unalias cdd

  cd
  export PS1=$_PS1
  if [ -n "$_PATH" ]; then
    export PATH=$_PATH
    export GOPATH=$_GOPATH
  fi
}

# alias
alias workon='__pp_workon'

# autocomplete
if [ -d $PROJECTS ]; then
  if [ -n "$BASH_VERSION" ]; then
    complete -W "$(__pp_complete)" workon
  elif [ -n "$ZSH_VERSION" ]; then
    __pp_zsh() {
      reply=( $(__pp_complete) )
    }
    compctl -K __pp_zsh __pp_workon
  fi
fi
