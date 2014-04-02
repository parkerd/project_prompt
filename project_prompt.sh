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

__pp_goenv() {
  export _GOPATH=$GOPATH
  export GOPATH=$__pp_dir
  export _PATH=$PATH
  export PATH=$GOPATH/bin:$PATH
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

  if [ "${__pp_name:0:3}" == "go/" ]; then
    __pp_goenv
    __pp_base=$__pp_dir
    if [ -z $GITHUB ]; then
      echo "Set \$GITHUB to ensure proper workspace setup."
      __pp_dir=$__pp_dir/src
    else
      __pp_dir=$__pp_dir/src/$GITHUB/${__pp_name:3}
    fi
  fi

  if [ ! -d $__pp_dir ]; then
    read -p "Create new project '$__pp_name'? "
    if [ "$REPLY" == "y" ]; then
      if [ "${__pp_name:0:3}" == "go/" ]; then
        mkdir -p $__pp_base/{bin,pkg,src}
      fi
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

  if [ -d ".git" ]; then
    export PS1=$(echo "$PS1" | sed 's/\\w/($(__pp_git_branch)|$__pp_name)$(__pp_pwd)/g')
  elif [ -d ".hg" ]; then
    export PS1=$(echo "$PS1" | sed 's/\\w/($(__pp_hg_status)$__pp_name)$(__pp_pwd)/g')
  else
    export PS1=$(echo "$PS1" | sed 's/\\w/[$__pp_name]$(__pp_pwd)/g')
  fi
}

__pp_git_branch() {
  status=$(cd $__pp_dir && git status)

  branch=$(echo "$status" | head -1 | cut -d' ' -f4-)
  if [ "$branch" == "" ]; then
    branch=$(echo "$status" | head -1 | cut -d' ' -f3-)
  fi

  if [ $(echo "$status" | egrep -c "Untracked|Change") -gt 0 ]; then
    echo "${branch}*"
  else
    echo $branch
  fi
}

__pp_hg_status() {
  if [ $(cd $_pp_dir && hg status | grep -c ^) -gt 0 ]; then
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
alias workon='__pp_work'

# autocomplete
if [ -d $PROJECTS ]; then
  complete -W "$(__pp_complete)" workon
fi
