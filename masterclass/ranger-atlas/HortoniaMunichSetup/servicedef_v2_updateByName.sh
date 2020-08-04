#!/bin/bash

#
# Update a service-def using Public API v2
#

realScriptDir=$(cd "$(dirname "$0")"; pwd)
source ${realScriptDir}/env_ranger.sh
source ./env_ranger.sh


serviceType=$1
inputFileName=$2


function checkUsage() {
  if [ "${serviceType}" == "" ]
  then
    echo "Usage: $0 serviceType [input-file]"
    exit 1
  fi

  if [ "${inputFileName}" == "" ]
  then
    inputFileName=`getDataFilePath "ranger-servicedef-${serviceType}.json"`
  fi

  if [ ! -f "${inputFileName}" ]
  then
    echo "${inputFileName}: does not exist"
    exit 1
  fi
}
checkUsage


output=`${CURL_CMDLINE} -X PUT -H "Content-Type: application/json" -H "Accept: application/json" -u ${RANGER_ADMIN_USER}:${RANGER_ADMIN_PASS} ${RANGER_ADMIN_URL}/service/public/v2/api/servicedef/name/${serviceType} -d @${inputFileName}`
ret=$?


if [ $ret == 0 ]
then
  echo ${output} | ${JSON_FORMATTER}
else
  echo "failed with error code: ${ret}"
fi
