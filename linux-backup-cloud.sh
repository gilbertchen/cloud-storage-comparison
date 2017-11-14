#!/bin/bash

if [ "$#" -eq 0 ]; then
    echo "Usage: $0 <test dir> <storage url>"
    exit 1
fi

if [ -z "$DUPLICACY_PATH" ]; then
    echo "DUPLICACY_PATH must be set to the path to the Dupicacy executable"
    exit 1
fi

# Set up directories
TEST_DIR=$1
BACKUP_DIR=${TEST_DIR}/linux
STORAGE_URL=$2

if [[ $3 ]]; then
    THREADS="-threads $3"
fi

PASSWORD=12345678

# Save passwords in these variables; only fill in for those storages that you want to test 
# See https://github.com/gilbertchen/duplicacy/blob/master/GUIDE.md#managing-passwords
export DUPLICACY_SSH_PASSWORD=
export DUPLICACY_DROPBOX_TOKEN=
export DUPLICACY_S3_ID=
export DUPLICACY_S3_SECRET=
export DUPLICACY_B2_ID=
export DUPLICACY_B2_KEY=
export DUPLICACY_AZURE_KEY=
export DUPLICACY_GCD_TOKEN=
export DUPLICACY_GCS_TOKEN=
export DUPLICACY_ONE_TOKEN=
export DUPLICACY_HUBIC_TOKEN=

# Wasabi and Amazon S3 share the same variables and here you can add Wasabi credentials
if [[ "${STORAGE_URL}" == *"wasabi"* ]]; then
    export DUPLICACY_S3_ID=
    export DUPLICACY_S3_SECRET=
fi

# Or you can set those variables in a passwords.sh file
if [ -f "${PWD}/passwords.sh" ]; then
    echo "loading passwords"    
    source ${PWD}/passwords.sh
fi
 
# Download the github repository if needed
if [ ! -d "${BACKUP_DIR}" ]; then
    git clone https://github.com/torvalds/linux.git ${BACKUP_DIR}
fi

function duplicacy_backup()
{
    pushd ${BACKUP_DIR}
    time env DUPLICACY_PASSWORD=${PASSWORD} ${DUPLICACY_PATH} backup -stats -hash ${THREADS} | grep -v Uploaded
    popd
}

function duplicacy_restore()
{
    pushd ${BACKUP_DIR}
    time env DUPLICACY_PASSWORD=${PASSWORD} ${DUPLICACY_PATH} restore -r $1 -stats -overwrite ${THREADS} | grep -v Downloaded
    popd
}

echo =========================================== init ========================================
rm -rf ${BACKUP_DIR}/.duplicacy
mkdir -p ${BACKUP_DIR}/.duplicacy

pushd ${BACKUP_DIR}
env DUPLICACY_PASSWORD=${PASSWORD} ${DUPLICACY_PATH} init test ${STORAGE_URL} -e
echo "-.git/" > ${BACKUP_DIR}/.duplicacy/filters

git checkout -f 4f302921c1458d790ae21147f7043f4e6b6a1085 # commit on 07/02/2016
duplicacy_backup

git checkout -f 3481b68285238054be519ad0c8cad5cc2425e26c # commit on 08/03/2016 
duplicacy_backup

git checkout -f 46e36683f433528bfb7e5754ca5c5c86c204c40a # commit on 09/02/2016 
duplicacy_backup

git checkout -f 566c56a493ea17fd321abb60d59bfb274489bb18 # commit on 10/05/2016 
duplicacy_backup

git checkout -f 1be81ea5860744520e06d0dfb9e3490b45902dbb # commit on 11/01/2016 
duplicacy_backup

git checkout -f ef3d232245ab7a1bf361c52449e612e4c8b7c5ab # commit on 12/02/2016 
duplicacy_backup

rm -rf ${BACKUP_DIR}/*

for i in `seq 1 6`; do
    duplicacy_restore $i
done

popd


