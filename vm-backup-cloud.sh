#!/bin/bash

# The first argument is the directory where snapshots of VirtualBox vms are stored.
# We expect three files from there: CentOS7-1.vdi, CentOS7-2.vdi, and CentOS7-3.vdi
if [ "$#" -eq 0 ]; then
    echo "Usage: $0 <vm dir> <test dir> <storage url>"
    exit 1
fi

if [ -z "$DUPLICACY_PATH" ]; then
    echo "DUPLICACY_PATH must be set to the path to the Dupicacy executable"
    exit 1
fi

# Set up directories
VM_DIR=$1
TEST_DIR=$2
BACKUP_DIR=${TEST_DIR}/cloud
STORAGE_URL=$3

if [[ $4 ]]; then
    THREADS="-threads $4"
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

# DigitalOcean and Amazon S3 share the same variables and here you can add Wasabi credentials
if [[ "${STORAGE_URL}" == *"digitalocean"* ]]; then
    export DUPLICACY_S3_ID=
    export DUPLICACY_S3_SECRET=
fi

# Or you can set those variables in a passwords.sh file
if [ -f "${PWD}/passwords.sh" ]; then
    echo "loading passwords"    
    source ${PWD}/passwords.sh
fi
 
function duplicacy_backup()
{
    pushd ${BACKUP_DIR}
    time env DUPLICACY_PASSWORD=${PASSWORD} ${DUPLICACY_PATH} backup -stats -hash ${THREADS} | grep -v Uploaded | grep -v Skipped
    popd
}

function duplicacy_restore()
{
    pushd ${BACKUP_DIR}
    time env DUPLICACY_PASSWORD=${PASSWORD} ${DUPLICACY_PATH} restore -r $1 -stats -overwrite ${THREADS} | grep -v "Downloaded chunk"
    popd
}

echo =========================================== init ========================================
rm -rf ${BACKUP_DIR}/*
rm -rf ${BACKUP_DIR}/.duplicacy
mkdir -p ${BACKUP_DIR}/.duplicacy

pushd ${BACKUP_DIR}
env DUPLICACY_PASSWORD=${PASSWORD} ${DUPLICACY_PATH} init test ${STORAGE_URL} -e

cp ${VM_DIR}/CentOS7-1.vdi ${BACKUP_DIR}/CentOS7.vid
duplicacy_backup

cp ${VM_DIR}/CentOS7-2.vdi ${BACKUP_DIR}/CentOS7.vid
duplicacy_backup

cp ${VM_DIR}/CentOS7-3.vdi ${BACKUP_DIR}/CentOS7.vid
duplicacy_backup

rm -rf ${BACKUP_DIR}/*

for i in `seq 1 3`; do
    duplicacy_restore $i
done

popd


