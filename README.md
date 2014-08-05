# Project Prompt

Simple bash wrapper for working on and switching between projects.

## Setup
Clone the repo and add the following to your .bashrc:
```bash
export PROJECTS=~/projects
source $PROJECTS/project_prompt/project_prompt.sh
```

If you'd like to organize your projects more you can add an array of subprojects:
```bash
export SUBPROJECTS=( sub1 sub2 )
```

## Usage
To see all available projects use the alias `workon`:
```bash
~ $ workon
projects:
project_prompt

projects/sub1:
project1 project2

projects/sub2:
project3
```

To enter a project:
```bash
~ $ workon project_prompt 
(master|project_prompt) $ pwd
/Users/pdebardelaben/projects/project_prompt
(master|project_prompt) $ 
```

When using git and hg, uncommited changes are indicated by an asterisk. If the project uses git, the current branch is also shown in the prompt:
```bash
(master|project_prompt) $ touch file
(master*|project_prompt) $ 
```

When not using git or hg, a square prompt is used:
```bash
[sub1/project1] $ 
```

When you change directories within a project the prompt contains the relative path:
```bash
[sub1/example1] $ cd path/in/your/project
[sub1/example1]/path/in/your/project $ 
```

Returning to the root of your project is as simple as `cd`:
```bash
[sub1/example1]/path/in/your/project $ cd
[sub1/example1] $ 
```

To return home and restore your original prompt type `cdd`:
```bash
[sub1/project1] $ cdd
~ $ 
```
