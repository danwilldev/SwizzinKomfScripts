#!/usr/bin/env bash

if [ ! -f /install/komf.sh]; then
    echo_error "You ain't got no komf, whacha doen"
    exit 1
fi

user=$(_get_master_username)
if [[ $(systemctl is-active komf) == "active" ]]; then
    wasactive=yes
    systemctl stop komf
fi
echo_progress_start "Downloading komf binary"
dlurl="$(curl -sNL https://api.github.com/repos/Snd-R/komf/releases/latest | jq -r '.assets[]?.browser_download_url | select(endswith("jar"))')"
wget "$dlurl" -O /opt/komf/komf.jar >> "${log}" 2>&1 || {
    echo_error "Download failed"
    exit 1
}
chown -R "$user":"$user" /opt/komf
echo_progress_done "Bin downloaded"

if [[ $wasactive == "yes" ]]; then
    systemctl start komf
fi