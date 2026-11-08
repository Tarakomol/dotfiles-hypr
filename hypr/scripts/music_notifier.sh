#!/usr/bin/env bash
TMP_DIR="/tmp/spotify_cover"
LOG="/tmp/spotify_cover.log"
mkdir -p "$TMP_DIR"
last_id=""

: >"$LOG"

WARP_PROXY="socks5h://127.0.0.1:40000"

if command -v magick &>/dev/null; then
  IM_CMD="magick"
elif command -v convert &>/dev/null; then
  IM_CMD="convert"
else
  echo "$(date): ОШИБКА - ни magick, ни convert не найдены!" >>"$LOG"
  IM_CMD=""
fi

playerctl --player=spotify metadata --format \
  '{{mpris:trackid}}|{{title}}|{{artist}}|{{mpris:artUrl}}' --follow |
  while IFS='|' read -r trackid title artist art_url; do
    [[ -z "$trackid" ]] && continue
    [[ "$trackid" == "$last_id" ]] && continue
    last_id="$trackid"

    id_safe="${trackid##*/}"
    COVER_PATH="$TMP_DIR/${id_safe}.jpg"
    ICON="-i spotify"

    if [[ "$art_url" == http* ]]; then
      if [[ ! -s "$COVER_PATH" ]]; then
        if curl -x "$WARP_PROXY" -sL -m 5 "$art_url" --output "$COVER_PATH.tmp" 2>>"$LOG"; then
          if [[ -s "$COVER_PATH.tmp" ]] && [[ -n "$IM_CMD" ]]; then
            if "$IM_CMD" "$COVER_PATH.tmp" -resize 300x300^ \
              -gravity center -extent 300x300 "$COVER_PATH" 2>>"$LOG"; then
              :
            else
              echo "$(date): ОШИБКА convert" >>"$LOG"
            fi
          fi
          rm -f "$COVER_PATH.tmp"
        else
          echo "$(date): ОШИБКА curl (через WARP proxy)" >>"$LOG"
        fi
      fi
      [[ -s "$COVER_PATH" ]] && ICON="-i $COVER_PATH"
    fi

    notify-send -r 27072 $ICON "$title" "$artist"
  done
