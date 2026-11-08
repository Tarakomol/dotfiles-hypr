#!/usr/bin/env bash
CONFIG_DIR="$HOME/.config/hypr"

# Функция для генерации цветов matgen по текущим обоям
update_colors() {
    # 1. Пытаемся вытащить текущие обои из swww или hyprpaper
    if command -v swww &> /dev/null; then
        # Получаем путь к картинке из активного состояния swww
        WALLPAPER=$(swww query 2>/dev/null | grep -oE '/[^ ]+\.(jpg|jpeg|png|webp)' | head -n 1)
    elif command -v hyprpaper > /dev/null; then
        WALLPAPER=$(ps aux | grep hyprpaper | grep -v grep | awk '{print $NF}' | head -1)
    fi

    # Fallback: ищем через swaybg
    if [ -z "$WALLPAPER" ] && command -v swaybg > /dev/null; then
        WALLPAPER=$(ps aux | grep swaybg | grep -v grep | awk '{print $NF}' | head -1)
    fi

    # 2. Если нашли обои, запускаем matugen для генерации новой обводки и темы
    if [ -n "$WALLPAPER" ] && command -v matgen > /dev/null; then
        # Передаем matgen изображение для генерации палитры границ
        matgen image "$WALLPAPER" > /dev/null 2>&1
    fi

    # 3. Применяем сгенерированный live-скрипт matgen, если он есть
    if [ -f "$CONFIG_DIR/colors-matgen-live.sh" ]; then
        bash "$CONFIG_DIR/colors-matgen-live.sh" > /dev/null 2>&1
    fi

    # 4. Обновляем основной конфиг, чтобы Hyprland перерисовал обводку окон
    touch "$CONFIG_DIR/hyprland.conf"
}

# Запуск мониторинга папки
inotifywait -m -r -e close_write --format '%w%f' "$CONFIG_DIR" | while read -r FILE; do
    if [[ "$FILE" != *"hyprland.conf"* ]]; then
        sleep 0.4
        update_colors
    fi
done
