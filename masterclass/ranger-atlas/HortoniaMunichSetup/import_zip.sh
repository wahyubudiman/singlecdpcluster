#!/bin/bash

#
# Get an entity by guid
#

realScriptDir=$(cd "$(dirname "$0")"; pwd)

source ${realScriptDir}/env_atlas.sh
source ./env_atlas.sh

inputFileName=$1


function checkUsage() {
  if [ "${inputFileName}" == "" ]
  then
    echo "Usage: $0 inputFileName"
    exit 1
  fi
}
checkUsage

url=${ATLAS_URL}/api/atlas/admin/import

output=`${CURL_CMDLINE} -X POST -u ${ATLAS_USER}:${ATLAS_PASS} -H "Accept: application/json" -H "Content-Type: multipart/form-data" -H "Cache-Control: no-cache" -F data=@${inputFileName} ${url}`
ret=$?

if [ $ret == 0 ]
then
  echo ${output} | ${JSON_FORMATTER}
  echo "imported from ${inputFileName}"
else
  echo "failed with error code: ${ret}"
fi
