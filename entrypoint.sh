#!/bin/bash

TZ=${TZ:-UTC}

echo "Setting timezone to ${TZ}"
ln -snf /usr/share/zoneinfo/${TZ} /etc/localtime
echo ${TZ} > /etc/timezone

echo "Initializing files and folders"
mkdir -p /data/cache /data/lib
if [ -z "$(ls -A /data/lib)" ]; then
  cp -r /var/lib/samba/* /data/lib/
fi
rm -rf /var/lib/cache /var/lib/samba
ln -sf /data/cache /var/cache/samba
ln -sf /data/lib /var/lib/samba

if [[ "$(yq --output-format=json e '(.. | select(tag == "!!str")) |= envsubst' /data/config.yml 2>/dev/null | jq '.auth')" != "null" ]]; then
  for auth in $(yq -j e '(.. | select(tag == "!!str")) |= envsubst' /data/config.yml 2>/dev/null | jq -r '.auth[] | @base64'); do
    _jq() {
      echo "${auth}" | base64 --decode | jq -r "${1}"
    }
    password=$(_jq '.password')
    if [[ "$password" = "null" ]] && [[ -f "$(_jq '.password_file')" ]]; then
      password=$(cat "$(_jq '.password_file')")
    fi
    echo "Creating user $(_jq '.user')/$(_jq '.group') ($(_jq '.uid'):$(_jq '.gid'))"
    id -g "$(_jq '.gid')" &>/dev/null || id -gn "$(_jq '.group')" &>/dev/null || addgroup -g "$(_jq '.gid')" -S "$(_jq '.group')"
    id -u "$(_jq '.uid')" &>/dev/null || id -un "$(_jq '.user')" &>/dev/null || adduser -u "$(_jq '.uid')" -G "$(_jq '.group')" "$(_jq '.user')" -SHD
    echo -e "$password\n$password" | smbpasswd -a -s "$(_jq '.user')"
    unset password
  done
fi

testparm -s

exec "$@"
