#!/bin/bash

#
# Get a service-def using Public API v2
#

realScriptDir=$(cd "$(dirname "$0")"; pwd)
source ${realScriptDir}/env_ranger.sh
source ./env_ranger.sh


serviceType=$1
outputFileName=$2


function checkUsage() {
  if [ "${serviceType}" == "" ]
  then
    echo "Usage: $0 serviceType [output-file]"
    exit 1
  fi

  if [ "${outputFileName}" == "" ]
  then
    outputFileName=`getDataFilePath "ranger-servicedef-${serviceType}.json"`
  fi
}
checkUsage


output=`${CURL_CMDLINE} -X GET -H "Content-Type: application/json" -u ${RANGER_ADMIN_USER}:${RANGER_ADMIN_PASS} ${RANGER_ADMIN_URL}/service/public/v2/api/servicedef/name/${serviceType}`
ret=$?


if [ $ret == 0 ]
then
  echo ${output} | ${JSON_FORMATTER} > ${outputFileName}
  echo "${serviceType}: service-def saved to ${outputFileName}"
else
  echo "failed with error code: ${ret}"
fi
