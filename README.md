# dotfiles-hypr

Мои конфиги для Hyprland и окружения. Сделаны под себя (два монитора), но можно
использовать как основу.

## Состав

| Папка | Что это |
| --- | --- |
| `hypr/` | Hyprland (Lua-конфиг в `conf/`), hypridle, hyprlock, скрипты |
| `waybar/` | Панель Waybar |
| `wofi/` | Лаунчер Wofi (частота запусков, прозрачность) |
| `kitty/` | Терминал Kitty |
| `fish/` | Fish shell + tide/fisher (без машинных `fish_variables`) |
| `cava/` | Аудио-визуализатор Cava |
| `matugen/` | Шаблоны Matugen для генерации цветов |
| `swaync/` | Центр уведомлений SwayNC |
| `rofi/` | Rofi (выбор обоев) |
| `gtk-3.0/`, `gtk-4.0/`, `nwg-look/`, `qt6ct/`, `xsettingsd/` | Настройки темы GTK/Qt |
| `btop/`, `fastfetch/` | Btop и Fastfetch |
| `fontconfig/` | Настройки шрифтов |
| `bin/` | Скрипты из `~/.local/bin` (обои и т.п.) |
| `Wallpapers/` | Обои |
| `mimeapps.list` | Приложения по умолчанию |

## Установка

Скопировать нужные папки в `~/.config` (и `bin/` в `~/.local/bin`), затем:

```bash
hyprctl reload
```

Цвета генерируются через [Matugen](https://github.com/InioX/matugen) по
`matugen/config.toml`; после смены обоев цвета обновляются автоматически.

## Зависимости

Hyprland, Waybar, Wofi, Kitty, Fish (+ fisher, tide), Cava, Matugen, SwayNC,
Rofi, Btop, Fastfetch, nwg-look, шрифты JetBrainsMono Nerd Font и Terminus.

## Примечание

Конфиги живые и могут отличаться от текущего состояния системы.
