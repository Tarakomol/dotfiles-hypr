#!/usr/bin/env bash

pkill -x wofi 2>/dev/null || true

for _ in {1..20}; do
    pgrep -x wofi >/dev/null 2>&1 || break
    sleep 0.05
done

pkill -KILL -x wofi 2>/dev/null || true

# Сортируем кэш drun по частоте запусков (по убыванию).
# wofi в режиме sort_order=default показывает записи из кэша
# в том порядке, в котором они лежат в файле, поэтому после
# сортировки самые часто запускаемые приложения оказываются сверху.
CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/wofi-drun"
if [ -f "$CACHE" ]; then
    tmp="$(mktemp)"
    if sort -rn "$CACHE" > "$tmp"; then
        mv "$tmp" "$CACHE"
    else
        rm -f "$tmp"
    fi
fi

wofi \
    --conf "$HOME/.config/wofi/config" \
    --style "$HOME/.config/wofi/style.css" \
    --show drun \
    --sort-order default \
    --fork
