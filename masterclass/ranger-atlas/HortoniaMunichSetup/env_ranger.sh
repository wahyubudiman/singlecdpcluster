export RANGER_ADMIN_URL=http://localhost:6080
export RANGER_ADMIN_USER=admin
export RANGER_ADMIN_PASS=admin

export JSON_FORMATTER="python -mjson.tool"
export CURL_CMDLINE="curl -f "

export DATA_DIR=data

if [ ! -d ${DATA_DIR} ]
then
  mkdir -p ${DATA_DIR}
fi

function getDataFilePath() {
  local fileName=$1

  echo "${DATA_DIR}/${fileName}"
}
