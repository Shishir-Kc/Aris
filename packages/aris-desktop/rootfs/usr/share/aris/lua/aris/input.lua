-- Keyboard, pointer and touchpad defaults.

-- The installer records the keyboard in the standard localectl location, so
-- the same layout applies to Hyprland, XWayland apps and anything else that
-- reads it.
local function system_keyboard()
  local kb = { layout = "us", variant = "", options = "" }
  local f = io.open("/etc/X11/xorg.conf.d/00-keyboard.conf", "r")
  if not f then
    return kb
  end
  local text = f:read("*a") or ""
  f:close()
  kb.layout = text:match('Option%s+"XkbLayout"%s+"([^"]*)"') or kb.layout
  kb.variant = text:match('Option%s+"XkbVariant"%s+"([^"]*)"') or kb.variant
  kb.options = text:match('Option%s+"XkbOptions"%s+"([^"]*)"') or kb.options
  return kb
end

return function(_, o)
  local kb = system_keyboard()

  hl.config({
    input = {
      kb_layout = o.kb_layout or kb.layout,
      kb_variant = o.kb_variant or kb.variant,
      kb_options = o.kb_options or kb.options,
      numlock_by_default = true,
      repeat_rate = 35,
      repeat_delay = 300,

      follow_mouse = 1,
      sensitivity = 0,

      touchpad = {
        natural_scroll = true,
        tap_to_click = true,
        disable_while_typing = true,
      },
    },
  })

  -- Three-finger horizontal swipe switches workspaces.
  hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
end
