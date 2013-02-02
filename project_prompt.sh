#!/usr/bin/env bash

# disable python virtualenv prompt
VIRTUAL_ENV_DISABLE_PROMPT=1

# functions
__pp_complete() {
  #ls -1 $PROJECTS
  project_list="$(ls -1 $PROJECTS)"
  for ((i=0; i < ${#SUBPROJECTS[*]}; i++)); do
    for sub in $(ls -1 $PROJECTS/${SUBPROJECTS[i]}); do
      project_list="$project_list\n${SUBPROJECTS[i]}/$sub"
    done
  done
  echo -e "$project_list"
}

__pp_pwd() {
  pwd | sed "s/$(echo $__pp_dir | sed 's/\//\\\//g')//"
}

__pp_work() {
  # return a list of __pp_dirs if one is not provided
  if [ $# -ne 1 ]; then
    project_list="$PROJECTS"
    for ((i=0; i < ${#SUBPROJECTS[*]}; i++)); do
      project_list="$project_list $PROJECTS/${SUBPROJECTS[i]}"
    done
    ls $project_list
    return
  fi

  if [ -n "$_PS1" ]; then
    export PS1=$_PS1
  fi

  __pp_name=$1
  __pp_dir=$PROJECTS/$__pp_name

  if [ ! -d $__pp_dir ]; then
    read -p "Create new project '$__pp_name'? "
    if [ "$REPLY" == "y" ]; then
      mkdir -p $__pp_dir && git init $__pp_dir >/dev/null
    else
      echo
      return
    fi
  fi

  if [ -z "$_PS1" ]; then
      export _PS1=$PS1
  fi

  alias cd='__pp_cd'
  alias cdd='__pp_quit'

  cd $__pp_dir

  if [ -d "./.git" ]; then
    export PS1=$(echo "$PS1" | sed 's/\\w/($(__pp_branch)|$__pp_name)$(__pp_pwd)/g')
  else
    export PS1=$(echo "$PS1" | sed 's/\\w/[$__pp_name]$(__pp_pwd)/g')
  fi
}

__pp_branch() {
  status=$(cd $__pp_dir && git status)
  branch=$(echo "$status" | head -1 | cut -d' ' -f4-)
  if [ $(echo "$status" | egrep -c "Untracked|Change") -gt 0 ]; then
    echo "${branch}*"
  else
    echo $branch
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
}

# alias
alias workon='__pp_work'

# autocomplete
if [ -d $PROJECTS ]; then
  complete -W "$(__pp_complete)" workon
fi
