-- ЛУА-КОНФИГ HYPRLAND (Главный точка входа)
local config_dir = os.getenv("HOME") .. "/.config/hypr/conf/"

dofile(config_dir .. "env.lua")
dofile(config_dir .. "autostart.lua")
dofile(config_dir .. "appearance.lua")
dofile(config_dir .. "input.lua")
dofile(config_dir .. "keybinds.lua")
