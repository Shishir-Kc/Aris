-- Look and feel: the Aris palette — shades of black and grey, milky white accent.
return function(_, _)
  hl.config({
    general = {
      gaps_in = 4,
      gaps_out = 10,
      border_size = 2,
      col = {
        active_border = { colors = { "rgba(ece8e1ee)", "rgba(8a8a8aee)" }, angle = 45 },
        inactive_border = "rgba(2a2a2acc)",
      },
      resize_on_border = true,
      allow_tearing = false,
      layout = "dwindle",
    },

    decoration = {
      rounding = 10,
      rounding_power = 2,
      active_opacity = 1.0,
      inactive_opacity = 0.97,

      shadow = {
        enabled = true,
        range = 14,
        render_power = 3,
        color = 0x66000000,
      },

      blur = {
        enabled = true,
        size = 6,
        passes = 2,
        vibrancy = 0.17,
      },
    },

    animations = {
      enabled = true,
    },

    dwindle = {
      preserve_split = true,
    },

    master = {
      new_status = "master",
    },

    misc = {
      force_default_wallpaper = 0,
      disable_hyprland_logo = true,
      disable_splash_rendering = true,
      focus_on_activate = true,
      key_press_enables_dpms = true,
      mouse_move_enables_dpms = true,
      background_color = 0xff0b0b0b,
      -- Let a restarted aris-shell take over a lock screen whose shell crashed.
      allow_session_lock_restore = true,
    },
  })

  hl.curve("aris", { type = "bezier", points = { { 0.22, 1 }, { 0.36, 1 } } })
  hl.curve("arisLinear", { type = "bezier", points = { { 0, 0 }, { 1, 1 } } })
  hl.curve("arisSpring", { type = "spring", mass = 1, stiffness = 260, dampening = 25 })

  hl.animation({ leaf = "global", enabled = true, speed = 8, bezier = "default" })
  hl.animation({ leaf = "border", enabled = true, speed = 5, bezier = "aris" })
  hl.animation({ leaf = "windows", enabled = true, speed = 4.5, spring = "arisSpring" })
  hl.animation({ leaf = "windowsIn", enabled = true, speed = 4, spring = "arisSpring", style = "popin 90%" })
  hl.animation({ leaf = "windowsOut", enabled = true, speed = 1.5, bezier = "arisLinear", style = "popin 90%" })
  hl.animation({ leaf = "fade", enabled = true, speed = 3, bezier = "aris" })
  hl.animation({ leaf = "layers", enabled = true, speed = 3.5, bezier = "aris" })
  hl.animation({ leaf = "layersIn", enabled = true, speed = 3.5, bezier = "aris", style = "fade" })
  hl.animation({ leaf = "layersOut", enabled = true, speed = 1.5, bezier = "arisLinear", style = "fade" })
  hl.animation({ leaf = "workspaces", enabled = true, speed = 3, bezier = "aris", style = "slide" })
  hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 3, bezier = "aris", style = "slidevert" })
end
