-- Aris · Hyprland bootstrap
--
-- Loaded with dofile() at the top of ~/.config/hypr/hyprland.lua, so it runs
-- on every config (re)load before anything is require()d.

local function env_or(name, fallback)
  local value = os.getenv(name)
  if value == nil or value == "" then
    return fallback
  end
  return value
end

local aris_path = env_or("ARIS_PATH", "/usr/share/aris")

-- Hyprland keeps its Lua state across `hyprctl reload`, and require() caches
-- modules. Drop ours so edits to the defaults are picked up on reload.
local stale = {}
for name in pairs(package.loaded) do
  if name == "aris" or name:sub(1, 5) == "aris." then
    table.insert(stale, name)
  end
end
for _, name in ipairs(stale) do
  package.loaded[name] = nil
end

-- Put the Aris module tree first on the search path, once.
local entries = aris_path .. "/lua/?.lua;" .. aris_path .. "/lua/?/init.lua;"
if package.path:sub(1, #entries) ~= entries then
  package.path = entries .. package.path
end
