#!/usr/bin/env bash
set -uo pipefail

# --- Не даём скрипту запуститься дважды параллельно (например, от двойного
#     нажатия хоткея). Лок держим только до момента, пока обои реально не
#     поставлены — дальше он снимается, чтобы следующий запуск не ждал
#     фоновую генерацию темы ---
LOCK_FILE="$HOME/.cache/wallpaper-picker.lock"
exec 200>"$LOCK_FILE"
if ! flock -n 200; then
  echo "wallpaper-picker: уже запущен, выходим" >&2
  exit 0
fi

# --- Явный дебаунс: не даём переключать обои чаще, чем раз в MIN_INTERVAL
#     секунд, независимо от того, сколько занимает фоновая часть ---
DEBOUNCE_FILE="$HOME/.cache/wallpaper-picker.last_run"
MIN_INTERVAL=1
now=$(date +%s)
last=$(cat "$DEBOUNCE_FILE" 2>/dev/null || echo 0)
if ((now - last < MIN_INTERVAL)); then
  echo "wallpaper-picker: слишком часто, подожди ещё $((MIN_INTERVAL - (now - last))) сек" >&2
  exit 0
fi
echo "$now" >"$DEBOUNCE_FILE"

WALLPAPER_DIR="$HOME/Wallpapers"
CACHE_FILE="$HOME/.cache/last_wallpapers.txt"
touch "$CACHE_FILE"

MON_MAIN="HDMI-A-1"
MON_PORTRAIT="DP-1"

# --- 0. Разбор аргументов: можно задать конкретные обои вместо рандома.
#     --pick        — выбрать основной монитор через wofi из списка файлов
#     [main]         — путь к файлу (абсолютный или относительно WALLPAPER_DIR)
#     [main] [portrait] — оба монитора конкретные
PICK_MODE=0
if [ "${1:-}" = "--pick" ]; then
  PICK_MODE=1
  shift
fi
ARG_MAIN="${1:-}"
ARG_PORTRAIT="${2:-}"

# Приводит пользовательский путь (абсолютный или относительно WALLPAPER_DIR)
# к полному пути; возвращает 1, если файла не существует
resolve_wallpaper() {
  local input="$1"
  if [ -f "$input" ]; then
    readlink -f "$input"
  elif [ -f "$WALLPAPER_DIR/$input" ]; then
    readlink -f "$WALLPAPER_DIR/$input"
  else
    return 1
  fi
}

# --- 1. Собираем все доступные обои ---
mapfile -t ALL_WALLPAPERS < <(find "$WALLPAPER_DIR" -type f \( -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" \))

if [ "${#ALL_WALLPAPERS[@]}" -lt 2 ]; then
  echo "wallpaper-picker: в $WALLPAPER_DIR меньше 2 картинок, нечего выбирать" >&2
  exit 1
fi

# --- Кэш миниатюр для превью в rofi. Полноразмерные 4K-картинки как иконки
#     грузятся долго и жрут память, поэтому один раз делаем аккуратные
#     уменьшенные копии и переиспользуем их, пока не изменится исходник ---
THUMB_DIR="$HOME/.cache/wallpaper-picker/thumbs"
mkdir -p "$THUMB_DIR"

wallpaper_thumb() {
  local src="$1" key out im
  key=$(printf '%s' "$src" | md5sum | cut -d' ' -f1)
  out="$THUMB_DIR/$key.jpg"
  if [ -f "$out" ] && [ ! "$src" -nt "$out" ]; then
    printf '%s' "$out"
    return 0
  fi
  if command -v magick >/dev/null; then im=magick; else im=convert; fi
  if "$im" "$src" -auto-orient -thumbnail '1000x1000>' -strip -quality 85 "$out" 2>/dev/null; then
    printf '%s' "$out"
  else
    printf '%s' "$src"
  fi
}

if [ "$PICK_MODE" -eq 1 ]; then
  if ! command -v rofi >/dev/null; then
    echo "wallpaper-picker: --pick с превью требует rofi" >&2
    exit 1
  fi

  # Прогреваем кэш миниатюр параллельно, чтобы окно открылось уже с картинками
  export THUMB_DIR
  export -f wallpaper_thumb
  printf '%s\0' "${ALL_WALLPAPERS[@]}" |
    xargs -0 -r -P 4 -I{} bash -c 'wallpaper_thumb "$1" >/dev/null' _ {}

  # Полноэкранная сетка миниатюр + большой предпросмотр выбранной обоины.
  # Навигация стрелками/колесом, Enter — выбрать, Esc — отмена.
  ARG_MAIN=$(
    for f in "${ALL_WALLPAPERS[@]}"; do
      printf '%s\0icon\x1f%s\n' "$(basename "$f")" "$(wallpaper_thumb "$f")"
    done | rofi -dmenu -show-icons -i -no-custom -matching fuzzy \
      -theme "$HOME/.config/rofi/wallpaper.rasi"
  )
  if [ -z "$ARG_MAIN" ]; then
    echo "wallpaper-picker: выбор отменён" >&2
    exit 0
  fi
fi

WALLPAPER_MAIN=""
WALLPAPER_PORTRAIT=""

if [ -n "$ARG_MAIN" ]; then
  WALLPAPER_MAIN=$(resolve_wallpaper "$ARG_MAIN") || {
    echo "wallpaper-picker: файл '$ARG_MAIN' не найден" >&2
    exit 1
  }
fi
if [ -n "$ARG_PORTRAIT" ]; then
  WALLPAPER_PORTRAIT=$(resolve_wallpaper "$ARG_PORTRAIT") || {
    echo "wallpaper-picker: файл '$ARG_PORTRAIT' не найден" >&2
    exit 1
  }
fi

# --- 2. Фильтрация обоев: выбираем только те файлы, которых НЕТ в кэше.
#     -x у grep — точное совпадение всей строки, а не подстроки (это был баг
#     в старой версии: файл мог случайно "вычёркиваться" другим похожим
#     именем/путём) ---
CANDIDATES=()
while IFS= read -r file; do
  CANDIDATES+=("$file")
done < <(printf "%s\n" "${ALL_WALLPAPERS[@]}" | grep -vFxf "$CACHE_FILE" 2>/dev/null || true)

# --- 3. Если перебрали почти все обои — сбрасываем кэш и берём полный список ---
if [ "${#CANDIDATES[@]}" -lt 2 ]; then
  : >"$CACHE_FILE"
  CANDIDATES=("${ALL_WALLPAPERS[@]}")
fi

# --- 4. То, что не задано вручную — выбираем случайно (не повторяя друг друга) ---
if [ -z "$WALLPAPER_MAIN" ]; then
  WALLPAPER_MAIN=$(printf "%s\n" "${CANDIDATES[@]}" | shuf -n 1)
fi
if [ -z "$WALLPAPER_PORTRAIT" ]; then
  WALLPAPER_PORTRAIT=$(printf "%s\n" "${CANDIDATES[@]}" | grep -vFx "$WALLPAPER_MAIN" | shuf -n 1)
  # если после исключения ничего не осталось (например, весь пул — это один
  # вручную заданный файл) — берём случайный из полного списка
  if [ -z "$WALLPAPER_PORTRAIT" ]; then
    WALLPAPER_PORTRAIT=$(printf "%s\n" "${ALL_WALLPAPERS[@]}" | grep -vFx "$WALLPAPER_MAIN" | shuf -n 1)
  fi
fi

if [ -z "$WALLPAPER_MAIN" ] || [ -z "$WALLPAPER_PORTRAIT" ]; then
  echo "wallpaper-picker: не удалось выбрать два разных файла" >&2
  exit 1
fi

# Фиксируем выбор в кэш сразу, чтобы не повторялись при следующих запусках
echo "$WALLPAPER_MAIN" >>"$CACHE_FILE"
echo "$WALLPAPER_PORTRAIT" >>"$CACHE_FILE"

# --- 5. Обои ставим СРАЗУ, до генерации темы — это самый заметный для глаза
#     шаг, и раньше он был в конце (потому и была задержка в 5-10 сек, пока
#     matugen анализировал картинку и Waybar перезапускался) ---
pkill wofi 2>/dev/null
killall swaybg 2>/dev/null
# exec 200>&- внутри форкнутого блока закрывает УНАСЛЕДОВАННУЮ копию fd лока
# именно в этом дочернем процессе — swaybg живёт долго (пока обои висят на
# экране), и без явного закрытия он держал бы лок открытым вечно, даже после
# unlock в родителе
(
  exec 200>&-
  swaybg -o "$MON_MAIN" -i "$WALLPAPER_MAIN" -m fill -o "$MON_PORTRAIT" -i "$WALLPAPER_PORTRAIT" -m fill
) &
disown

# --- Обои поставлены — снимаем лок здесь для родительского процесса.
#     Дальше идёт фоновая генерация темы, которая больше НЕ блокирует
#     следующий запуск скрипта (тот регулируется только дебаунсом выше) ---
flock -u 200

# --- 6. Дальше всё, что не влияет на то, что видно "прямо сейчас", идём в
#     фон одним блоком: генерация темы, обновление CSS, релоад баров.
#     exec 200>&- первой строкой — по той же причине: waybar в этом блоке
#     тоже долгоживущий процесс и не должен держать открытым fd лока ---
{
  exec 200>&-
  if matugen image "$WALLPAPER_MAIN" --mode dark --type scheme-vibrant --prefer=saturation; then
    touch ~/.config/waybar/style.css
    touch ~/.config/wofi/style.css
    touch ~/.config/waybar/colors-matugen.css
    touch ~/.config/wofi/colors-matugen.css

    # Горячий релоад конфига Hyprland: config-only перечитывает hyprland.lua
    # (вместе с colors-matugen.lua) и НЕ трогает мониторы, поэтому проходит
    # за миллисекунды без перезапуска WM и без фризов.
    hyprctl reload config-only >/dev/null 2>&1 || true
    # config-only сбрасывает курсор к дефолтному — возвращаем текущую тему.
    hyprctl setcursor gaster-cursor-linux 32 >/dev/null 2>&1 || true

    killall -SIGUSR1 kitty 2>/dev/null

    # Если твой Waybar собран с поддержкой SIGUSR2 — это горячий релоад стилей
    # без полного перезапуска (быстрее и без моргания бара). Если версия
    # старая и SIGUSR2 не поддерживается, оставь вариант ниже с killall+nohup.
    if pgrep -x waybar >/dev/null; then
      pkill -SIGUSR2 waybar 2>/dev/null || {
        killall waybar 2>/dev/null
        nohup waybar >/dev/null 2>&1 &
        disown
      }
    else
      nohup waybar >/dev/null 2>&1 &
      disown
    fi
  else
    echo "wallpaper-picker: matugen упал, тема не обновлена (обои поставлены)" >&2
  fi
} &
disown
