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

If the project uses git, the current branch is shown in the prompt.  Uncommited changes are indicated by an asterisk:
```bash
(master|project_prompt) $ touch file
(master*|project_prompt) $ 
```

Else a square prompt is used:
```bash
[sub1/project1] $
```

When you change directories within a project the prompt contains the relative path:
```bash
[sub1/example1] $ cd lib
[sub1/example1]/lib $ 
```

Returning to the root of your project is as simple as `cd`:
```bash
[sub1/example1]/lib $ cd
[sub1/example1] $ 
```

To return home and restore your original prompt type `cdd`:
```bash
[sub1/project1] $ cdd
~ $
```