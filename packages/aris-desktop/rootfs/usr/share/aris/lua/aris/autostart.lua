-- Session services, started once when Hyprland comes up (not on reload).
return function(aris, _)
  hl.on("hyprland.start", function()
    -- Hand the Wayland session environment to systemd/D-Bus activated
    -- services (portals, polkit agent) before anything asks for them.
    hl.exec_cmd("dbus-update-activation-environment --systemd --all")

    hl.exec_cmd("systemctl --user start hyprpolkitagent.service")
    hl.exec_cmd("aris-wallpaper restore")
    hl.exec_cmd("waybar")
    hl.exec_cmd("mako")
    hl.exec_cmd("nm-applet --indicator")
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")

    if aris.live then
      hl.exec_cmd("aris-welcome")
    else
      hl.exec_cmd("hypridle")
      hl.exec_cmd("aris-first-run")
    end
  end)
end
