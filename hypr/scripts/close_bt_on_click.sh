#!/bin/bash

# Ждём появления окна
while ! hyprctl clients | grep -q "class: Blueman-manager"; do
  sleep 0.1
done

# Получаем ID окна
WIN=$(hyprctl clients | grep -A5 "class: Blueman-manager" | grep "window" | awk '{print $2}')

# Следим за кликами
hyprctl -j events | while read -r event; do
  if echo "$event" | grep -q "\"event\":\"mouse\""; then
    # Проверяем, что клик был НЕ по окну Bluetooth
    ACTIVE=$(hyprctl activewindow | grep "window" | awk '{print $2}')
    if [[ "$ACTIVE" != "$WIN" ]]; then
      hyprctl dispatch killactive
      exit 0
    fi
  fi
done
