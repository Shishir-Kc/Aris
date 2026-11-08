-- Aris · Hyprland
--
-- Aris keeps its defaults in /usr/share/aris/lua; they improve with each
-- aris-desktop update. This file picks your apps and then loads your own
-- settings from the files next to it, which override the defaults.
--
-- Hyprland docs: https://wiki.hypr.land/Configuring/Start/
-- Keybindings:   SUPER + /

dofile((os.getenv("ARIS_PATH") or "/usr/share/aris") .. "/lua/bootstrap.lua")

local aris = require("aris")

aris.setup({
  terminal = "kitty",
  browser = "firefox",
  file_manager = "thunar",
  launcher = "aris-menu apps",

  -- Keyboard defaults to the layout chosen at install time.
  -- kb_layout = "us,de",
  -- kb_options = "grp:alt_shift_toggle,caps:escape",

  -- false = start from zero and define every keybinding in binds.lua.
  default_binds = true,
})

-- Your settings (loaded in this order, after the Aris defaults).
aris.user("monitors")
aris.user("input")
aris.user("looknfeel")
aris.user("binds")
aris.user("autostart")
