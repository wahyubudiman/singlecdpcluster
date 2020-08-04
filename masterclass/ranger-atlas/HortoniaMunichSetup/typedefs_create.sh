#!/bin/bash

#
# Create an entity-def
#

realScriptDir=$(cd "$(dirname "$0")"; pwd)

source ${realScriptDir}/env_atlas.sh
source ./env_atlas.sh

inputFileName=$1

function checkUsage() {
  if [ "${inputFileName}" == "" ]
  then
    echo "Usage: $0 input-file"
    exit 1
  fi

  if [ ! -f "${inputFileName}" ]
  then
    echo "${inputFileName}: does not exist"
    exit 1
  fi
}
checkUsage

output=`${CURL_CMDLINE} -X POST -u ${ATLAS_USER}:${ATLAS_PASS} -H "Accept: application/json" -H "Content-Type: application/json" ${ATLAS_URL}/api/atlas/v2/types/typedefs -d @${inputFileName}`
ret=$?


if [ $ret == 0 ]
then
  echo ${output} | ${JSON_FORMATTER}
else
  echo "failed with error code: ${ret}"
fi
