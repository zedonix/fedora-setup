#!/usr/bin/env bash

sudo systemctl disable --now ananicy-cpp.service

sudo find /usr/local -iname '*ananicy*'

sudo rm -rf /etc/ananicy.d
sudo rm -rf /etc/ananicy.conf

sudo rm -rf /usr/share/ananicy

sudo rm -f /etc/systemd/system/ananicy-cpp.service
sudo systemctl daemon-reload
