-- Session environment. Applied before any client starts.
return function(aris, o)
  hl.env("ARIS_PATH", aris.path)
  if aris.live then
    hl.env("ARIS_LIVE", "1")
  end

  hl.env("XCURSOR_THEME", o.cursor_theme)
  hl.env("XCURSOR_SIZE", tostring(o.cursor_size))
  hl.env("HYPRCURSOR_SIZE", tostring(o.cursor_size))

  -- Prefer native Wayland everywhere, fall back to XWayland.
  hl.env("GDK_BACKEND", "wayland,x11,*")
  hl.env("QT_QPA_PLATFORM", "wayland;xcb")
  hl.env("QT_QPA_PLATFORMTHEME", "gtk3")
  hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
  hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")

  -- Portals and screen sharing key off these.
  hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
  hl.env("XDG_SESSION_DESKTOP", "Hyprland")
  hl.env("XDG_SESSION_TYPE", "wayland")

  hl.config({
    xwayland = {
      force_zero_scaling = true,
    },
    ecosystem = {
      no_update_news = true,
      no_donation_nag = true,
    },
  })
end
