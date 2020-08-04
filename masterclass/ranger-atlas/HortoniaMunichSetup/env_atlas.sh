export ATLAS_URL=http://localhost:21000
export ATLAS_USER=admin
export ATLAS_PASS=admin

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
