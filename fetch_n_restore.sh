#!/bin/bash

urlencode() {
    # urlencode <string>
    old_lc_collate=$LC_COLLATE
    LC_COLLATE=C
    
    local length="${#1}"
    for (( i = 0; i < length; i++ )); do
        local c="${1:i:1}"
        case $c in
            [a-zA-Z0-9.~_-]) printf "$c" ;;
            *) printf '%%%02X' "'$c" ;;
        esac
    done
    
    LC_COLLATE=$old_lc_collate
}

urldecode() {
    # urldecode <string>

    local url_encoded="${1//+/ }"
    printf '%b' "${url_encoded//%/\\x}"
}

if [[ $# -ne 1 ]]; then
    echo -e "Usage: $0 BLOB_VER"
    exit 1
fi
BLOB_VER=${1:-"12.4"}

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RESET='\033[0m'

API="http://127.0.0.1:8000"
USERNAME="root"
PASSWORD="toor"

SAVE_PATH="saved.shsh2"
rm -f ${SAVE_PATH}

DEVICE_NAME="$(ideviceinfo --key DeviceName)"
ECID="$(ideviceinfo --key DieID)"
HWMODEL="$(ideviceinfo --key HardwareModel)"
PRODUCT_VERSION="$(ideviceinfo --key ProductVersion)"
PRODUCT_TYPE="$(ideviceinfo --key ProductType)"
PRODUCT_TYPE_ENCODED="$(urlencode $PRODUCT_TYPE)"
GENERATOR="0x1111111111111111"
# echo ${ECID} >> ecids.txt

BUILD_ROOT=$(cd `dirname $0`; pwd)
echo -e "[-] ${GREEN}launch fetching process${RESET}"
cd "${BUILD_ROOT}"
echo -e "[!] ${YELLOW}chdir \"${BUILD_ROOT}\"${RESET}"
echo -e "[!] ${YELLOW}ECID: ${ECID}${RESET}"
echo -e "[!] ${YELLOW}HWMODEL: ${HWMODEL}${RESET}"

rm -f curl.output
if [ ! -s curl.token ]; then
  echo -e "[-] ${GREEN}api login...${RESET}"
  # login
  # use -L to follow 302 redirects and get access token
  curl -sS -L \
    "${API}/admin/login/?next=/api/token.json" \
    -H 'Accept: */*' \
    -H 'Accept-Encoding: gzip, deflate' \
    -H 'Cache-Control: no-cache' \
    -H 'Connection: keep-alive' \
    -H 'Content-Type: application/x-www-form-urlencoded' \
    -H 'User-Agent: PostmanRuntime/7.17.1' \
    -d "username=${USERNAME}&password=${PASSWORD}" \
    -c curl.cookie -o curl.token
  if [ ! -s curl.token ]; then
    echo -e "[x] ${RED}api login failed${RESET}"
    exit 1
  fi
fi

ACCESS_TOKEN="$(cat curl.token | jq -r ".token")"
echo -e "[!] ${YELLOW}api token: ${ACCESS_TOKEN}${RESET}"

# register device
echo -e "[-] ${GREEN}register device ${ECID}...${RESET}"
curl -sS -L \
  "${API}/api/register/" \
  -H 'Accept: */*' \
  -H 'Accept-Encoding: gzip, deflate' \
  -H 'Cache-Control: no-cache' \
  -H 'Connection: keep-alive' \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  -H 'User-Agent: PostmanRuntime/7.17.1' \
  -d "token=${ACCESS_TOKEN}&name=${DEVICE_NAME}&hw_model=${HWMODEL}&product_type=${PRODUCT_TYPE_ENCODED}&ios_version=${PRODUCT_VERSION}&ecid=${ECID}&generator=${GENERATOR}" \
  -b curl.cookie -o curl.output

# fetch shsh2
echo -e "[-] ${GREEN}fetching shsh2 blobs for ${BLOB_VER}...${RESET}"
curl -sS -L \
  "${API}/api/fetch/" \
  -H 'Accept: */*' \
  -H 'Accept-Encoding: gzip, deflate' \
  -H 'Cache-Control: no-cache' \
  -H 'Connection: keep-alive' \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  -H 'User-Agent: PostmanRuntime/7.17.1' \
  -d "token=${ACCESS_TOKEN}&ecid=${ECID}&blob_version=${BLOB_VER}" \
  -b curl.cookie -o curl.output

STATUS=$(head -n 1 curl.output)
if [[ ${STATUS} == "<?xml version=\"1.0\" encoding=\"UTF-8\"?>" ]]; then
  cp curl.output ${SAVE_PATH}
else
  STATUS=$(cat curl.output | jq -r ".status")
  if [[ ${STATUS} == "200" ]]; then
    # download shsh2
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
  # your futurerestore command for HardwareModel N71AP here
elif [ ${HWMODEL} == "N71MAP" ]; then
  # your futurerestore command for HardwareModel N71MAP here
fi

