#!/usr/bin/env bash
set -euo pipefail

CONFIG_DIR="$HOME/.config/hypr"

# 1. Устанавливает обои через swaybg (работает всегда, не зависит от службы)
set_wallpaper() {
    local wallpaper="$1"
    if [ ! -f "$wallpaper" ]; then
        echo "Error: wallpaper file not found: $wallpaper" >&2
        exit 1
    fi

    # Убиваем старые процессы wallpaper
    pkill -f swaybg || true

    # Запускаем swaybg в фоне
    swaybg -i "$wallpaper" --resize stretch &
    disown

    # Ждем применения
    sleep 0.5
}

# 2. Генерируем палитру через matugen
generate_colors() {
    local wallpaper="$1"
    local temp_dir="$CONFIG_DIR/.temp"
    mkdir -p "$temp_dir"

    # matugen hyphenate генерирует цвета из изображения
    matugen hyphenate image "$wallpaper" --format code > "$temp_dir/colors.txt" 2>/dev/null || {
        # Fallback: если matugen hyphenate не поддерживается, используем matugen color
        matugen color "dark" > "$temp_dir/colors.txt" 2>/dev/null || true
    }
}

# 3. Парсит цвета из вывода matugen
parse_colors() {
    local colors_file="$CONFIG_DIR/.temp/colors.txt"
    if [ ! -f "$colors_file" ]; then
        return 1
    fi

    # Парсим hex-цвета из вывода matugen (формат: "#RRGGBB" или "RRGGBB")
    local colors
    colors=$(sed -n 's/.*\(#[0-9a-fA-F]\{6\}\).*/\1/p' "$colors_file" | head -2)

    local color_count
    color_count=$(echo "$colors" | grep -c . || true)

    if [ "$color_count" -lt 2 ]; then
        return 1
    fi

    local color1 color2
    color1=$(echo "$colors" | sed -n '1p')
    color2=$(echo "$colors" | sed -n '2p')

    # Удаляем '#' если есть
    color1="${color1#\#}"
    color2="${color2#\#}"

    # Преобразуем hex в rgba для hyprctl (для простоты используем rgb формат)
    local r1 g1 b1 r2 g2 b2
    r1="$(echo "$color1" | cut -c1-2)"
    g1="$(echo "$color1" | cut -c3-4)"
    b1="$(echo "$color1" | cut -c5-6)"
    r2="$(echo "$color2" | cut -c1-2)"
    g2="$(echo "$color2" | cut -c3-4)"
    b2="$(echo "$color2" | cut -c5-6)"

    echo "rgb($r1$g1$b1) rgb($r2$g2$b2)"
}

# 4. Применяет цвета через hyprctl
apply_colors() {
    local colors
    colors=$(parse_colors)
    if [ -z "$colors" ]; then
        echo "Could not parse colors from matugen output" >&2
        return 1
    fi

    local active_border inactive_border
    active_border=$(echo "$colors" | awk '{print $1}')
    inactive_border=$(echo "$colors" | awk '{print $2}')

    # Применяем через IPC — мгновенно, без фризов
    hyprctl keyword general.col.active_border "$active_border" 2>/dev/null || true
    hyprctl keyword general.col.inactive_border "$inactive_border" 2>/dev/null || true

    echo "Applied active_border=$active_border, inactive_border=$inactive_border"
}

# 5. Сохраняет цвета в Lua-файл для сохранения состояния при перезагрузке
save_colors_to_lua() {
    local colors
    colors=$(parse_colors)
    if [ -z "$colors" ]; then
        return 0
    fi

    local active_border inactive_border
    active_border=$(echo "$colors" | awk '{print $1}')
    inactive_border=$(echo "$colors" | awk '{print $2}')

    # Переписываем colors-matugen.lua
    cat > "$CONFIG_DIR/colors-matugen.lua" <<EOF
return {
    primary = "$active_border",
    on_primary = "rgb(003060)",
    surface = "rgb(0f141c)",
    outline = "$inactive_border",
}
EOF

    # Переписываем colors-matugen-live.sh
    cat > "$CONFIG_DIR/colors-matgen-live.sh" <<EOF
hyprctl --batch "keyword general:col.active_border $active_border ; keyword general:col.inactive_border $inactive_border"
EOF

    chmod +x "$CONFIG_DIR/colors-matugen-live.sh"

    echo "Saved colors to $CONFIG_DIR/colors-matugen.lua"
}

# --- ГЛАВНАЯ ЛОГИКА ---

WALLPAPER="${1:-}"

# Если путь не передан — ищем последние обои из swaybg
if [ -z "$WALLPAPER" ]; then
    # Пытаемся получить из swaybg (если запущен)
    WALLPAPER=$(ps aux | grep swaybg | grep -v grep | awk '{print $NF}' | head -1)
    if [ -z "$WALLPAPER" ] || [ ! -f "$WALLPAPER" ]; then
        echo "No wallpaper provided and no active wallpaper found." >&2
        exit 1
    fi
fi

# Шаг 1: Устанавливаем обои
set_wallpaper "$WALLPAPER"

# Шаг 2: Генерируем палитру
generate_colors "$WALLPAPER"

# Шаг 3: Применяем цвета мгновенно
apply_colors

# Шаг 4: Сохраняем для будущего
save_colors_to_lua

echo "Done: wallpaper=$WALLPAPER"
EOF
