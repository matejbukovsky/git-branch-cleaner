#!/bin/sh

# defaults
REPOSITORY="local"
AUTHOR="bukovsky@medio.cz"
PROJECT_FOLDER="current"

# colors
RED='\033[0;31m'
NC='\033[0m'
YEL='\033[1;33m'
GRN='\033[0;32m'

# loading options
while [ $# -gt 1 ]
do
  option="$1"
  case $option in
    -pf|--project-folder)
    PROJECT_FOLDER=${2};
    shift
    ;;
    -r|--repository)
    REPOSITORY=${2}
    shift
    ;;
    -a|--author)
    AUTHOR=${2};
    shift
    ;;
  esac
  shift
done

# manual
if [ "$1" = "man" ]; then
    echo
    echo "You can change default settings by following options:"
    echo
    printf "%s-\t%s\n" "-pf|--project-folder" "Define path to git repository root dir.";
    printf "%s-\t%s\n" "-r|--repository" "You can set local or remote repositories.";
    printf "%s-\t\t%s\n" "-a|--author" "Author of the repositories.";
    echo
    exit
fi

# check requirements
if [ $PROJECT_FOLDER = "current" ]; then
  if [ ! -d .git ]; then
    echo "${RED}Current folder is not GIT repository! Please, specify or go to project folder.${NC}"
    exit
  fi
else
  if [ ! -d $PROJECT_FOLDER ]; then
    echo "${RED}Project folder does not exist!${NC}"
    exit
  fi

  cd $PROJECT_FOLDER

  if [ ! -d .git ]; then
    echo "${RED}Passed project folder is not GIT repository!${NC}"
    exit
  fi
fi

echo "${GRN}Searching branches in${YEL} ${REPOSITORY} ${GRN}repository for author${YEL} $AUTHOR"
echo

if [ $REPOSITORY = "local" ]; then
  branches=`git for-each-ref --format='%(refname:short) %(authoremail)' | grep ${AUTHOR} | awk '{print $1}' | grep --invert-match 'origin*'`
elif [ $REPOSITORY = "remote" ]; then
  branches=`git for-each-ref --format='%(refname:short) %(authoremail)' | grep ${AUTHOR} | awk '{print $1}' | grep 'origin*'`
else
  echo "${RED}Repository location ${YEL}${REPOSITORY}${RED} not recognized. Specify local or remote repository.${NC}"
fi


# the logic
if [ ${#branches[@]} -eq 0 ]; then
  echo "${YEL}No remote branches found${NC}"
  exit
fi

for branch in $branches
do
  if [ $branch != "${branch#*master}" ] || [ $branch != "${branch#*HEAD}" ]; then
    continue
  fi

  echo "${YEL}Delete $branch? [y/N]${NC}"
  read confirm;  
  if [ "$confirm" = "y" ] ; then
    if [ $REPOSITORY = "local" ]; then
      git branch -D ${branch}
    elif [ $REPOSITORY = "remote" ]; then
      branchName=$(echo $branch | sed 's/origin\///g')
      git push origin :${branchName}
    fi
    echo "${GRN}Branch: $branch removed...${NC}"
  fi
done
