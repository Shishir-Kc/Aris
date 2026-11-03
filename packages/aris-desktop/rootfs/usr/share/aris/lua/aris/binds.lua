-- Aris keybindings. Every bind carries a description: SUPER + / lists them.
--
-- To change one, rebind the same keys in ~/.config/hypr/binds.lua (it loads
-- later), or hl.unbind("SUPER + Q") first. To drop all of these, pass
-- default_binds = false to aris.setup().
return function(aris, o)
  local SUPER = "SUPER"

  local function bind(keys, dispatcher, description, opts)
    local options = opts or {}
    options.description = description
    return hl.bind(keys, dispatcher, options)
  end

  local function run(cmd)
    return hl.dsp.exec_cmd(cmd)
  end

  -- Applications ------------------------------------------------------------
  bind(SUPER .. " + Return", run(o.terminal), "Terminal")
  bind(SUPER .. " + Space", run(o.launcher), "App launcher")
  bind(SUPER .. " + E", run(o.file_manager), "File manager")
  bind(SUPER .. " + B", run(o.browser), "Web browser")

  -- Windows -----------------------------------------------------------------
  bind(SUPER .. " + Q", hl.dsp.window.close(), "Close window")
  bind(SUPER .. " + F", hl.dsp.window.fullscreen({ mode = "fullscreen" }), "Fullscreen")
  bind(SUPER .. " + M", hl.dsp.window.fullscreen({ mode = "maximized" }), "Maximize")
  bind(SUPER .. " + V", hl.dsp.window.float({ action = "toggle" }), "Toggle floating")
  bind(SUPER .. " + P", hl.dsp.window.pseudo(), "Pseudo-tile")
  bind(SUPER .. " + J", hl.dsp.layout("togglesplit"), "Toggle split direction")
  bind(SUPER .. " + G", hl.dsp.group.toggle(), "Toggle window group")

  local directions = { left = "l", right = "r", up = "u", down = "d" }
  local resize_step = {
    left = { x = -40, y = 0 },
    right = { x = 40, y = 0 },
    up = { x = 0, y = -40 },
    down = { x = 0, y = 40 },
  }
  for key, dir in pairs(directions) do
    bind(SUPER .. " + " .. key, hl.dsp.focus({ direction = dir }), "Focus " .. key)
    bind(SUPER .. " + SHIFT + " .. key, hl.dsp.window.swap({ direction = dir }), "Swap window " .. key)
    bind(
      SUPER .. " + CTRL + " .. key,
      hl.dsp.window.resize({ x = resize_step[key].x, y = resize_step[key].y, relative = true }),
      "Resize window " .. key,
      { repeating = true }
    )
  end

  bind("ALT + Tab", function()
    hl.dispatch(hl.dsp.window.cycle_next())
    hl.dispatch(hl.dsp.window.bring_to_top())
  end, "Cycle windows")

  bind(SUPER .. " + mouse:272", hl.dsp.window.drag(), "Move window (drag)", { mouse = true })
  bind(SUPER .. " + mouse:273", hl.dsp.window.resize(), "Resize window (drag)", { mouse = true })

  -- Workspaces --------------------------------------------------------------
  for i = 1, 10 do
    local key = tostring(i % 10)
    bind(SUPER .. " + " .. key, hl.dsp.focus({ workspace = i }), "Workspace " .. i)
    bind(SUPER .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }), "Move window to workspace " .. i)
  end

  bind(SUPER .. " + Tab", hl.dsp.focus({ workspace = "previous" }), "Previous workspace")
  bind(SUPER .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }), "Next workspace")
  bind(SUPER .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }), "Previous workspace (scroll)")

  bind(SUPER .. " + grave", hl.dsp.workspace.toggle_special("scratchpad"), "Toggle scratchpad")
  bind(
    SUPER .. " + SHIFT + grave",
    hl.dsp.window.move({ workspace = "special:scratchpad" }),
    "Move window to scratchpad"
  )

  -- System ------------------------------------------------------------------
  bind(SUPER .. " + Escape", run("aris-menu power"), "Power menu")
  bind(SUPER .. " + slash", run("aris-keybinds"), "Show keybindings")
  bind(SUPER .. " + SHIFT + V", run("aris-clipboard"), "Clipboard history")
  bind(SUPER .. " + N", run("makoctl dismiss --all"), "Dismiss notifications")
  bind(SUPER .. " + SHIFT + N", run("makoctl restore"), "Restore last notification")
  bind(SUPER .. " + SHIFT + R", run("hyprctl reload"), "Reload Hyprland config")

  bind("Print", run("aris-screenshot region"), "Screenshot region")
  bind(SUPER .. " + SHIFT + S", run("aris-screenshot region"), "Screenshot region")
  bind("SHIFT + Print", run("aris-screenshot screen"), "Screenshot screen")
  bind(SUPER .. " + Print", run("aris-screenshot window"), "Screenshot window")

  if aris.live then
    -- The live user has no password, so a lock screen could not be unlocked.
    bind(SUPER .. " + I", run("aris-welcome --install"), "Install Aris")
  else
    bind(SUPER .. " + L", run("aris-lock"), "Lock screen")
  end

  -- Hardware keys (work on the lock screen too) -----------------------------
  local hw = { locked = true, repeating = true }
  bind("XF86AudioRaiseVolume", run("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), "Volume up", hw)
  bind("XF86AudioLowerVolume", run("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), "Volume down", hw)
  bind("XF86AudioMute", run("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), "Mute", { locked = true })
  bind("XF86AudioMicMute", run("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), "Mute microphone", { locked = true })
  bind("XF86MonBrightnessUp", run("brightnessctl -e4 -n2 set 5%+"), "Brightness up", hw)
  bind("XF86MonBrightnessDown", run("brightnessctl -e4 -n2 set 5%-"), "Brightness down", hw)

  local media = { locked = true }
  bind("XF86AudioNext", run("playerctl next"), "Next track", media)
  bind("XF86AudioPrev", run("playerctl previous"), "Previous track", media)
  bind("XF86AudioPlay", run("playerctl play-pause"), "Play / pause", media)
  bind("XF86AudioPause", run("playerctl play-pause"), "Play / pause", media)
end
