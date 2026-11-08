-- Цветовая схема
local activeBorderColors = { "rgb(fabd2f)", "rgb(d79921)" }
local activeBorderAngle = 45
local inactiveBorderColor = "rgb(3c3836)"

----------------------
---- ВНЕШНИЙ ВИД  ----
----------------------

hl.config({
	general = {
		gaps_in = 5,
		gaps_out = 10,
		border_size = 2,
		col = {
			active_border = { colors = activeBorderColors, angle = activeBorderAngle },
			inactive_border = inactiveBorderColor,
		},
		layout = "dwindle",
	},
	decoration = {
		rounding = 12,
		active_opacity = 1.0,
		inactive_opacity = 0.92,
		blur = {
			enabled = true,
			size = 6,
			passes = 3,
			new_optimizations = true,
			ignore_opacity = true,
			xray = false,
		},
	},
	animations = {
		enabled = true,
	},
})

local colors_file = os.getenv("HOME") .. "/.config/hypr/colors-matugen.lua"

-- Принудительно сбрасываем кэш Lua для этого файла
package.loaded[colors_file] = nil

local success, colors = pcall(dofile, colors_file)
if not success or type(colors) ~= "table" then
	colors = {
		primary = "rgb(33ccff)",
		outline = "rgb(595959)",
	}
end

hl.config({
	general = {
		gaps_in = 5,
		gaps_out = 10,
		border_size = 2,
		col = {
			active_border = colors.primary or activeBorderColors[1],
			inactive_border = colors.outline or inactiveBorderColor,
		},
		layout = "dwindle",
	},
})

-- Анимации
hl.curve("easeOutQuint", { type = "bezier", points = { { 0.23, 1 }, { 0.32, 1 } } })
hl.curve("md3_decel", { type = "bezier", points = { { 0.05, 0.7 }, { 0.1, 1 } } })

hl.animation({ leaf = "windows", enabled = true, speed = 3, bezier = "md3_decel", style = "popin 60%" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 3, bezier = "md3_decel", style = "popin 60%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 3, bezier = "md3_decel", style = "popin 60%" })
hl.animation({ leaf = "border", enabled = true, speed = 10, bezier = "default" })
hl.animation({ leaf = "fade", enabled = true, speed = 2.5, bezier = "md3_decel" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 4, bezier = "easeOutQuint", style = "slidefade 20%" })

-- Лейаут и системное
hl.config({
	master = {
		new_status = "master",
	},
	misc = {
		force_default_wallpaper = 0,
		disable_hyprland_logo = true,
	},
})

--------------------------------
---- ПРАВИЛА ОКОН И ВОРКСПЕЙСОВ ----
--------------------------------
hl.window_rule({
	name = "suppress-maximize-events",
	match = { class = ".*" },
	suppress_event = "maximize",
})

hl.window_rule({
	name = "fix-xwayland-drags",
	match = {
		class = "^$",
		title = "^$",
		xwayland = true,
		float = true,
		fullscreen = false,
		pin = false,
	},
	no_focus = true,
})

hl.window_rule({
	name = "move-hyprland-run",
	match = { class = "hyprland-run" },
	move = "20 monitor_h-120",
	float = true,
})

hl.window_rule({
	name = "wofi-opacity",
	match = { class = "^(wofi)$" },
	opacity = "1.0 override 1.0 override",
	stay_focused = true,
})

-- Не блокировать экран, пока открыто полноэкранное приложение:
-- видео на весь экран, игры и т.п.
hl.window_rule({
	name = "idle-inhibit-fullscreen",
	match = { class = ".*" },
	idle_inhibit = "fullscreen",
})
