#!/usr/bin/env bash
# Уходит в сон только когда ничего не играет; пока играет, ждёт
while playerctl -a status 2>/dev/null | grep -q Playing; do
  sleep 30
done
systemctl suspend
