-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")

------------------
---- МОНИТОРЫ ----
------------------
-- Левый монитор — AOC
hl.monitor({
	output = "DP-1",
	mode = "1920x1080@60",
	position = "1920x0",
	scale = 1,
	transform = 3,
})

-- Правый монитор — MKG (основной)
hl.monitor({
	output = "HDMI-A-1",
	mode = "1920x1080@100",
	position = "0x0",
	scale = 1,
})

-- Привязка рабочих пространств
hl.workspace_rule({ workspace = "10", monitor = "DP-1", default = true })
hl.workspace_rule({ workspace = "1", monitor = "HDMI-A-1", default = true })
