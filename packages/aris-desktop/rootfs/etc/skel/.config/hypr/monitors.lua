-- Monitors. List them with: hyprctl monitors all
-- https://wiki.hypr.land/Configuring/Basics/Monitors/

-- Any monitor: preferred mode, placed automatically, auto scale.
hl.monitor({
  output = "",
  mode = "preferred",
  position = "auto",
  scale = "auto",
})

-- Examples:
-- hl.monitor({ output = "eDP-1", mode = "2880x1800@120", position = "0x0", scale = 2 })
-- hl.monitor({ output = "DP-1", mode = "2560x1440@144", position = "auto-right", scale = 1 })
