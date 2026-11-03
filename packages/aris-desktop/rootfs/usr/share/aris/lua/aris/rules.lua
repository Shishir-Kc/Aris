-- Window and layer rules.
return function(_, _)
  -- Apps asking to maximize themselves shouldn't fight the tiler.
  hl.window_rule({
    name = "aris-suppress-maximize",
    match = { class = ".*" },
    suppress_event = "maximize",
  })

  -- XWayland drag-and-drop helper windows must never take focus.
  hl.window_rule({
    name = "aris-xwayland-drag-fix",
    match = { class = "^$", title = "^$", xwayland = true, float = true, fullscreen = false, pin = false },
    no_focus = true,
  })

  -- Small utility and settings windows float, centred.
  local floating = table.concat({
    "org.pulseaudio.pavucontrol",
    "nm-connection-editor",
    ".blueman-manager-wrapped",
    "blueman-manager",
    "nwg-look",
    "xdg-desktop-portal-gtk",
    "org.gnome.FileRoller",
    "aris.float",
  }, "|")
  hl.window_rule({
    name = "aris-float-utilities",
    match = { class = "^(" .. floating .. ")$" },
    float = true,
    center = true,
    size = { 900, 620 },
  })

  -- Open/save dialogs from any app.
  hl.window_rule({
    name = "aris-float-dialogs",
    match = { title = "^(Open File|Open Folder|Save As|Save File|Select a File|Choose Files?|File Upload).*" },
    float = true,
    center = true,
  })

  -- The live-session welcome and the installer run in a dedicated terminal class.
  hl.window_rule({
    name = "aris-welcome",
    match = { class = "^aris\\.(welcome|installer)$" },
    float = true,
    center = true,
    size = { 960, 680 },
  })

  -- Firefox picture-in-picture stays on top.
  hl.window_rule({
    name = "aris-pip",
    match = { title = "^Picture-in-Picture$" },
    float = true,
    pin = true,
    keep_aspect_ratio = true,
  })

  -- Blur behind the launcher and notifications.
  hl.layer_rule({ name = "aris-blur-launcher", match = { namespace = "^launcher$" }, blur = true, ignore_alpha = 0.2 })
  hl.layer_rule({ name = "aris-blur-notifications", match = { namespace = "^notifications$" }, blur = true, ignore_alpha = 0.2 })
  hl.layer_rule({ name = "aris-blur-bar", match = { namespace = "^waybar$" }, blur = true, ignore_alpha = 0.2 })
end
