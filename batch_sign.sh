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

BUILD_ROOT=$(cd `dirname $0`; pwd)
echo -e "[-] ${GREEN}launch signing process${RESET}"
cd "${BUILD_ROOT}"
echo -e "[!] ${YELLOW}chdir \"${BUILD_ROOT}\"${RESET}"

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

old_IFS=$IFS # save the field separator
IFS=$'\n' # new field separator, the end of line
for ECID in $(cat ecids.txt)
do
    # sign device
    echo -e "[-] ${GREEN}sign device ${ECID} for ${BLOB_VER}...${RESET}"
    curl -sS -L \
    "${API}/api/sign/" \
    -H 'Accept: */*' \
    -H 'Accept-Encoding: gzip, deflate' \
    -H 'Cache-Control: no-cache' \
    -H 'Connection: keep-alive' \
    -H 'Content-Type: application/x-www-form-urlencoded' \
    -H 'User-Agent: PostmanRuntime/7.17.1' \
    -d "token=${ACCESS_TOKEN}&ecid=${ECID}&ios_version=${BLOB_VER}&async=true" \
    -b curl.cookie \
    -w "\n"
done
IFS=$old_IFS # restore default field separator

