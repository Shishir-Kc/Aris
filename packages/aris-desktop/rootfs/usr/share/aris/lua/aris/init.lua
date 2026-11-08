-- Aris · Hyprland defaults
--
-- This tree is owned by the aris-desktop package and replaced on upgrade.
-- Don't edit it: personal settings go in ~/.config/hypr/*.lua, which load
-- after these defaults and therefore win.

local M = {}

local function env_or(name, fallback)
  local value = os.getenv(name)
  if value == nil or value == "" then
    return fallback
  end
  return value
end

local function file_exists(path)
  local f = io.open(path, "r")
  if f then
    f:close()
    return true
  end
  return false
end

M.path = env_or("ARIS_PATH", "/usr/share/aris")
M.home = os.getenv("HOME") or ""
M.config_home = env_or("XDG_CONFIG_HOME", M.home .. "/.config")

-- The live ISO ships this marker; installed systems never have it.
-- ARIS_LIVE=1 forces live behaviour (used by scripts/check.sh).
M.live = os.getenv("ARIS_LIVE") == "1" or file_exists("/etc/aris-live")

M.file_exists = file_exists

-- Defaults for aris.setup(). Anything here can be overridden per user.
M.defaults = {
  terminal = "kitty",
  browser = "firefox",
  file_manager = "thunar",
  launcher = "aris-menu apps",
  -- Set to false to skip every Aris keybinding and define your own.
  default_binds = true,
  -- Keyboard: left unset, the system layout chosen at install time is used
  -- (/etc/X11/xorg.conf.d/00-keyboard.conf). Set e.g. kb_layout = "us,de".
  kb_layout = nil,
  kb_variant = nil,
  kb_options = nil,
  cursor_theme = "Adwaita",
  cursor_size = 24,
}

local function merge(base, extra)
  local out = {}
  for k, v in pairs(base) do
    out[k] = v
  end
  for k, v in pairs(extra or {}) do
    out[k] = v
  end
  return out
end

-- Apply the Aris defaults. Called once from ~/.config/hypr/hyprland.lua.
function M.setup(opts)
  local o = merge(M.defaults, opts)
  M.opts = o

  require("aris.env")(M, o)
  require("aris.look")(M, o)
  require("aris.input")(M, o)
  if o.default_binds then
    require("aris.binds")(M, o)
  end
  require("aris.rules")(M, o)
  require("aris.autostart")(M, o)
end

-- Load ~/.config/hypr/<name>.lua if it exists. dofile() (not require) so the
-- file is re-read on every reload and a missing file is not an error.
function M.user(name)
  local path = M.config_home .. "/hypr/" .. name .. ".lua"
  if file_exists(path) then
    dofile(path)
  end
end

return M
