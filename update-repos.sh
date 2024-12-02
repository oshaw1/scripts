#!/bin/bash 

# Updates or clones the repositories specified in each project in the current directory
# on the default branch.
# Execute in a top level directory where you want to have your <project>/<repo> structure.
# Requires curl and JQ. Get from https://stedolan.github.io/jq/download/

# Set TOKEN to be your token from bitbucket
# or use your password when prompted.
TOKEN=

FORCE=""

function usage() {
    echo "usage: update-repos.sh [-fh] [<project directory>]"
	echo "You may specify an optional project directory to only operate on that project."
	echo "-f will use 'git checkout -force' and overwrite local changes."
	echo "-h will display this brief help"
    exit 1
}

while getopts ?hf opt; do
        case $opt in
        f) FORCE="--force"
           shift;;
        ?) usage;;
		h) usage;;
        esac
done


# if on windows, JQ belongs in /c/users/<user>/bin
if [ -x /usr/bin/jq ]; then
    JQ=/usr/bin/jq
else
    JQ=~/bin/jq-win64.exe
fi

PROJ_ENDPOINT=https://EXAMPLE/rest/api/1.0/projects/
LIMIT='?limit=100'
ROOT=`pwd`
SERVER=ssh://git@EXAMPLE:7999/
SUFFIX=.git
FAILS=${ROOT}/errorfile.txt
bbpw=""
err=0

listProjects () {
    if [ ! -z $TOKEN ]; then
        curl -H "Authorization: Bearer $TOKEN"  ${PROJ_ENDPOINT%/}/${LIMIT} | ${JQ}  '.values[].key'| tr -d '"' | tr -d '\r'
    else
        getpw
        curl -su `id -un`:$bbpw ${PROJ_ENDPOINT%/} | ${JQ}  '.values[].key'| tr -d '"' | tr -d '\r'
    fi
}


listReposJQ() {
    cd ${ROOT}
    if [ ! -z $TOKEN ]; then
    	curl -H "Authorization: Bearer $TOKEN"  ${PROJ_ENDPOINT%/}/${1%/}/repos/${LIMIT} | ${JQ} '.|.values[].slug' | tr -d '"' | tr -d '\r'
    else    
	getpw
    	curl -su `id -un`:$bbpw ${PROJ_ENDPOINT%/}/${1%/}/repos/${LIMIT} | ${JQ} '.|.values[].slug' | tr -d '"' | tr -d '\r'
    fi
}

defaultBranch() {

    if [ ! -z $TOKEN ]; then
        curl -H "Authorization: Bearer $TOKEN"  ${PROJ_ENDPOINT%/}/${1%/}/repos/${2%/}/branches/default | ${JQ} '.displayId'| tr -d '"' | tr -d '\r'
    else
        getpw
        curl -su `id -un`:$bbpw ${PROJ_ENDPOINT%/}/${1%/}/repos/${2%/}/branches/default | ${JQ} '.displayId'| tr -d '"' | tr -d '\r'
    fi
}


toLower() {
    echo $1 | tr '[:upper:]' '[:lower:]'
}

cloneOrUpdate() {
    cd ${ROOT}
    if [[ ! -d $1 ]]; then
	mkdir $1
    fi

    cd $1
    if [[ -d $2 ]]; then
        cd $2
        echo "In `pwd`:"
        echo "Fetching $3 ..."
        git fetch --prune 
        DEFAULT_BRANCH=$(defaultBranch $1 $2)
        echo "Default branch is: $DEFAULT_BRANCH ..."
        git checkout ${FORCE} $DEFAULT_BRANCH
        if [[ "$?" != "0" ]]; then
            echo "Could not checkout $1 $2 $DEFAULT_BRANCH"
            [[ "$?" != "0" ]] && { err=1; echo "${1%/}/$2" >> $FAILS; }
        else
            echo "Pulling $3 ..."
            git pull 
            [[ "$?" != "0" ]] && { err=1; echo "${1%/}/$2" >> $FAILS; }
        fi
    else
        echo "Try cloning $3 into ${ROOT%/}/$1 ..."
        cd ${ROOT%/}/$1
        git clone $3
        [[ "$?" != "0" ]] && { err=1; echo "${1%/}/$2" >> $FAILS; }
    fi
}

cleanup() {
    rm $FAILS
}

getpw () {
	read -p "Bitbucket password (for REST call):" -s bbpw 
	echo
}

if [[ $# = 1 && $1 != "" ]]; then
    projs=${1%/}/
else
    projs=$(listProjects)
fi

echo "Updating projects:"
echo "$projs"
echo "....."

for proj in ${projs}; do
    repos=$(listReposJQ ${proj})
    echo "Updating repos:"
    echo $repos 
    echo "....."
    echo
    for repo in $repos ; do
        lproj=$(toLower ${proj})
	url=${SERVER%/}/${lproj%/}/${repo%/}${SUFFIX}
        echo "Project ${proj}, checking ${url}"
        cloneOrUpdate ${proj} ${repo} ${url}
	echo "----------------------------------------------------------------------------------"
	echo
    done
done

[[ $err != 0 ]] && echo -e "\n\nErrors were reported pulling these repositories: " && cat $FAILS && cleanup