#!/bin/bash

# Log to Swizzin.log
export log=/root/logs/swizzin.log
touch $log

systemctl disable --now -q komf
rm /etc/systemd/system/komf.service
systemctl daemon-reload -q

if [[ -f /install/.nginx.lock ]]; then
    rm /etc/nginx/apps/komf.conf
    systemctl reload nginx
fi

rm /install/.komf.lock
rm -rf "/opt/komf/"