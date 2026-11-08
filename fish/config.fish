if status is-interactive
    set -g fish_greeting ""
    alias ls='lsd'
    zoxide init fish | source

    # Быстрый доступ к модулям Hyprland
    alias h-binds="nvim ~/.config/hypr/conf/keybinds.lua"
    alias h-auto="nvim ~/.config/hypr/conf/autostart.lua"
    alias h-app="nvim ~/.config/hypr/conf/appearance.lua"
    alias h-input="nvim ~/.config/hypr/conf/input.lua"
    alias h-env="nvim ~/.config/hypr/conf/env.lua"
    alias h-main="nvim ~/.config/hypr/hyprland.lua"

    # Быстрый переход в папку с конфигами
    function hconf
        cd ~/.config/hypr/conf/
        nvim .
    end
end

# overwrite greeting
# potentially disabling fastfetch
#function fish_greeting
#    # smth smth
#end
# Яркая подсветка аргументов и путей
set -g fish_color_valid_path cyan --underline
set -g fish_color_param f8f8f2
fastfetch
