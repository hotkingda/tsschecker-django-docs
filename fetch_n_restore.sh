#!/bin/bash

if [[ $# -ne 1 ]]; then
    echo -e "Usage: $0 BLOB_VERSION"
    exit 1
fi

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RESET='\033[0m'

API="http://127.0.0.1:8000"
USERNAME="root"
PASSWORD="toor"

ECID="$(ideviceinfo --key DieID)"
HWMODEL="$(ideviceinfo --key HardwareModel)"
BLOB_VERSION=${1:-"12.4"}
SAVE_PATH="saved.shsh2"

BUILD_ROOT=$(cd `dirname $0`; pwd)
echo -e "[-] ${GREEN}launch fetching process${RESET}"
cd "${BUILD_ROOT}"
echo -e "[!] ${YELLOW}chdir \"${BUILD_ROOT}\"${RESET}"

rm -f ${SAVE_PATH}
rm -f curl.output

echo -e "[!] ${YELLOW}ECID: ${ECID}${RESET}"
echo -e "[!] ${YELLOW}HWMODEL: ${HWMODEL}${RESET}"
echo -e "[-] ${GREEN}fetching shsh2 blobs for ${BLOB_VERSION}...${RESET}"

if [ ! -s curl.token ]; then
  echo -e "[-] ${GREEN}api login...${RESET}"
  curl -sS \
    "${API}/admin/login/?next=/api/token.json" \
    -H 'Accept: */*' \
    -H 'Accept-Encoding: gzip, deflate' \
    -H 'Cache-Control: no-cache' \
    -H 'Connection: keep-alive' \
    -H 'Content-Type: application/x-www-form-urlencoded' \
    -H 'User-Agent: PostmanRuntime/7.17.1' \
    -d "username=${USERNAME}&password=${PASSWORD}" \
    -c curl.cookie
  curl -sS \
    "${API}/api/token.json" \
    -H 'Accept: */*' \
    -H 'Accept-Encoding: gzip, deflate' \
    -H 'Cache-Control: no-cache' \
    -H 'Connection: keep-alive' \
    -H 'User-Agent: PostmanRuntime/7.17.1' \
    -b curl.cookie -o curl.token
  if [ ! -s curl.token ]; then
    echo -e "[x] ${RED}api login failed${RESET}"
    exit 1
  fi
fi

TOKEN="$(cat curl.token | jq -r ".token")"
echo -e "[!] ${YELLOW}api token: ${TOKEN}${RESET}"

curl -sS -L \
  "${API}/api/fetch/" \
  -H 'Accept: */*' \
  -H 'Accept-Encoding: gzip, deflate' \
  -H 'Cache-Control: no-cache' \
  -H 'Connection: keep-alive' \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  -H 'User-Agent: PostmanRuntime/7.17.1' \
  -d "token=${TOKEN}&ecid=${ECID}&blob_version=${BLOB_VERSION}" \
  -b curl.cookie -o curl.output

STATUS=$(head -n 1 curl.output)
if [[ ${STATUS} == "<?xml version=\"1.0\" encoding=\"UTF-8\"?>" ]]; then
  cp curl.output ${SAVE_PATH}
else
  STATUS=$(cat curl.output | jq -r ".status")
  if [[ ${STATUS} == "200" ]]; then
    echo -e "[-] ${GREEN}signature exists, downloading...${RESET}"
    STATUS_URL=$(cat curl.output | jq -r ".url")
    curl -sS -L \
      "${API}${STATUS_URL}" \
      -H 'Accept: */*' \
      -H 'Accept-Encoding: gzip, deflate' \
      -H 'Cache-Control: no-cache' \
      -H 'Connection: keep-alive' \
      -H 'User-Agent: PostmanRuntime/7.17.1' \
      -b curl.cookie -o curl.output
    STATUS=$(head -n 1 curl.output)
    if [[ ${STATUS} == "<?xml version=\"1.0\" encoding=\"UTF-8\"?>" ]]; then
      cp curl.output ${SAVE_PATH}
    fi
  fi
fi

if [ -s ${SAVE_PATH} ]; then
  echo -e "[-] ${GREEN}shsh2 blobs saved at: ${SAVE_PATH}${RESET}"
else
  STATUS_MSG=$(cat curl.output | jq -r ".msg")
  echo -e "[x] ${RED}${STATUS_MSG}${RESET}"
  exit 1
fi

echo -e "[-] ${GREEN}futurerestore device...${RESET}"
if [ ${HWMODEL} == "N71AP" ]; then
  echo -e ""
elif [ ${HWMODEL} == "N71MAP" ]; then
  echo -e ""
fi

