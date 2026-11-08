-------------------
---- АВТОЗАПУСК ----
-------------------
hl.on("hyprland.start", function()
	hl.exec_cmd("~/.local/bin/wallpaper-picker.sh")
	hl.exec_cmd("discord")
	hl.exec_cmd("~/.config/hypr/scripts/music_notifier.sh")
	hl.exec_cmd("steam")
	hl.exec_cmd("swaync")
	hl.exec_cmd("hypridle")
	hl.exec_cmd("~/.config/hypr/scripts/gamepad_idle_inhibit.py")
	hl.exec_cmd("hyprsunset -t 4500")
	hl.exec_cmd("hyprpaper")
	hl.exec_cmd("waybar")
	hl.exec_cmd("/usr/bin/playerctld")
	hl.exec_cmd("hyprctl setcursor retrosmart-xcursor-mac-ish-classic")
	hl.exec_cmd("swaybg -o HDMI-A-1 -i ~/Wallpapers/beeteto.png -o DP-1 -i ~/wallpapers/typing_cheatsheet.png")
end)
