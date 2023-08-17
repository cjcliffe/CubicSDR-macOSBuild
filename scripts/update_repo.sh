#!/bin/bash

if [ $# -lt 2 ]; then 
    echo "./update_repo.sh <Folder> <Repo>"
    exit 1
fi

UPD_FOLDER="$1"
UPD_REPO="$2"
UPD_BRANCH_PARAM="$3"
UPD_BRANCH=""

if [ ! $UPD_BRANCH_PARAM = "" ]; then
    UPD_BRANCH="-b $UPD_BRANCH_PARAM"
fi

if [ -d "$UPD_FOLDER" ]; then
    pushd .
    cd "$UPD_FOLDER"
    git pull
    popd
else
    git clone $UPD_REPO $UPD_FOLDER $UPD_BRANCH
fi

