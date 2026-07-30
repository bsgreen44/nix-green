{ pkgs, lib, wallpaper, hyprland, hidpi ? false, ... }:

let
  monitorConfig =
    if hidpi then ''
      hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1.33 })
      hl.env("GDK_SCALE", "1.33")
    '' else ''
      hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })
    '';
in
{
  # Hyprland packages
  home.packages = with pkgs; [
    brightnessctl
    libnotify    # Provides the notify-send command
    mako         # notifications
    grim         # screenshot
    slurp        # screenshot
    gnome-calculator
    wl-clipboard
    swaybg       # wallpaper config
    swayimg      # Image viewer
    bibata-cursors
    rofi-power-menu
  ];

  # clipboard manager
  services.cliphist.enable = true;

  # Enable GNOME Keyring
  services.gnome-keyring = {
    enable = true;
    components = [ "secrets" ];
  };

  # Set the GTK Theme
  gtk = {
    enable = true;
    font = {
      name  = "JetBrainsMono Nerd Font";
      size = 10;
    };
    theme = {
      name = "Adwaita-dark";
      package = pkgs.gnome-themes-extra;
    };
    
    gtk4.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
    };
    gtk4.theme = null;
    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
    };
  };

  # Hyprland configuration
  wayland.windowManager.hyprland = {
    enable = true;
    package = hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
    configType = "lua";

    # Use extraConfig for raw Lua configuration (hl.* API) instead of the settings
    # attrset. Since Hyprland 0.55 hyprlang is deprecated in favor of Lua, so this
    # is emitted to ~/.config/hypr/hyprland.lua. See https://hypr.land/news/26_lua/
    extraConfig = ''
      local terminal  = "ghostty"
      local mod       = "SUPER"
      local menu      = [[rofi -show drun -show-icons -display-drun ""]]
      local browser   = "brave"
      local powermenu = [[rofi -show power-menu -theme-str 'inputbar { enabled: false; }' -theme-str 'window {width: 225px;}' -theme-str 'window {height: 260px;}' -modi "power-menu:rofi-power-menu"]]


      -- Monitor configuration
      ${monitorConfig}

      -- Optional per-machine overrides (monitor layout, keybinds, etc.).
      -- With Lua the local override file is Lua too; dofile a missing file is a
      -- harmless no-op thanks to pcall.
      -- pcall(dofile, os.getenv("HOME") .. "/.config/hypr/local.lua")

      -- Cursor configuration
      hl.env("XCURSOR_THEME", "Bibata-Modern-Classic")
      hl.env("XCURSOR_SIZE", "20")
      hl.config({ cursor = { no_hardware_cursors = false } })

      -- Autostart
      hl.on("hyprland.start", function()
        hl.exec_cmd("waybar")
        hl.exec_cmd("pkill dunst; mako")
        hl.exec_cmd("wl-paste --type text --watch cliphist store")
        hl.exec_cmd("wl-paste --type image --watch cliphist store")
        hl.exec_cmd("swaybg -i ${wallpaper} -m fill")
      end)

      -- Input configuration
      hl.config({
        input = {
          kb_layout = "us",
          follow_mouse = 1,
          sensitivity = 0,
          touchpad = {
            natural_scroll = false,
          },
        },
      })

      -- Group bar
      hl.config({
        group = {
          groupbar = {
            font_family = "JetBrainsMono Nerd Font",
            font_size = 10,
          },
        },
      })

      -- General settings (dwindle is also available as layout = "dwindle")
      hl.config({
        general = {
          layout = "scrolling",
          gaps_in = 3,
          gaps_out = 7,
          border_size = 2,
          col = {
            active_border = { colors = { "rgba(cba6f7ed)", "rgba(89b4faed)" }, angle = 45 },
            inactive_border = "rgba(595959aa)",
          },
        },
      })
      hl.workspace_rule({ workspace = 10, layout = "dwindle" })
      hl.workspace_rule({ workspace = 9, layout = "dwindle" })
      hl.workspace_rule({ workspace = 8, layout = "dwindle" })

      -- Hyprland scrolling (a core layout in Lua, no longer under plugin)
      hl.config({
        scrolling = {
          column_width = 0.5,
          fullscreen_on_one_column = true,
        },
      })

      -- Decorations
      hl.config({
        decoration = {
          rounding = 8,
          blur = { enabled = false },
          shadow = { enabled = false },
        },
      })

      -- Animations
      hl.config({ animations = { enabled = true } })
      hl.curve("myBezier", { type = "bezier", points = { {0.05, 0.9}, {0.1, 1.05} } })
      hl.animation({ leaf = "windows",     enabled = true, speed = 7,  bezier = "myBezier" })
      hl.animation({ leaf = "windowsOut",  enabled = true, speed = 7,  bezier = "default", style = "popin 80%" })
      hl.animation({ leaf = "border",      enabled = true, speed = 10, bezier = "default" })
      hl.animation({ leaf = "borderangle", enabled = true, speed = 8,  bezier = "default" })
      hl.animation({ leaf = "fade",        enabled = true, speed = 7,  bezier = "default" })
      hl.animation({ leaf = "workspaces",  enabled = true, speed = 6,  bezier = "default", style = "slidevert" })

      -- Layout
      hl.config({ dwindle = { preserve_split = true } })

      -- Master layout (alternative)
      hl.config({ master = { new_status = "master" } })

      -- Window rules
      hl.window_rule({
        name = "float-utilities",
        match = { class = "^(gnome-disks|thunar|com.nextcloud.desktopclient.nextcloud|org.gnome.Calculator)$" },
        float = true,
        center = true,
        size = "900 600",
      })

      hl.window_rule({
        name = "float-swayimg",
        match = { class = "^(swayimg)$" },
        float = true,
        center = true,
      })

      hl.window_rule({
        name = "float-title",
        match = { title = "^(float)$" },
        float = true,
        center = true,
        size = "900 600",
      })

      hl.window_rule({
        name = "fullscreen-title",
        match = { title = "^(full)$" },
        fullscreen = true,
      })

      -- ---Keybindings

      -- Application launchers
      hl.bind(mod .. " + Return",     hl.dsp.exec_cmd(terminal))
      hl.bind(mod .. " + SHIFT + B",  hl.dsp.exec_cmd(browser))
      hl.bind(mod .. " + SHIFT + F",  hl.dsp.exec_cmd("thunar"))
      hl.bind(mod .. " + SHIFT + O",  hl.dsp.exec_cmd("obsidian"))
      hl.bind(mod .. " + SHIFT + V",  hl.dsp.exec_cmd("codium"))
      hl.bind(mod .. " + SHIFT + M",  hl.dsp.exec_cmd(terminal .. " --title=float -e btop"))
      hl.bind(mod .. " + SHIFT + T",  hl.dsp.exec_cmd(terminal .. " --title=float -e sudo tsui"))
      hl.bind(mod .. " + SHIFT + N",  hl.dsp.exec_cmd(terminal .. " -e nvim"))
      hl.bind(mod .. " + SHIFT + G",  hl.dsp.exec_cmd(terminal .. " -e lazygit"))
      hl.bind(mod .. " + SHIFT + A",  hl.dsp.exec_cmd(terminal .. " -e opencode"))
      hl.bind(mod .. " + Q",          hl.dsp.window.close())
      hl.bind(mod .. " + SHIFT + ESCAPE", hl.dsp.exit())
      hl.bind(mod .. " + T",          hl.dsp.window.float({ action = "toggle" }))
      hl.bind(mod .. " + SPACE",      hl.dsp.exec_cmd(menu))
      hl.bind(mod .. " + P",          hl.dsp.window.pseudo())
      hl.bind(mod .. " + U",          hl.dsp.layout("togglesplit"))
      hl.bind(mod .. " + F",          hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))
      -- routes through hypridle's guarded lock_cmd to avoid double hyprlock
      hl.bind(mod .. " + L",          hl.dsp.exec_cmd("loginctl lock-session"))
      -- Z = "zzz", manual screensaver
      hl.bind(mod .. " + SHIFT + Z",  hl.dsp.exec_cmd("screensaver"))
      hl.bind(mod .. " + ESCAPE",     hl.dsp.exec_cmd(powermenu))
      hl.bind(mod .. " + CTRL + V",   hl.dsp.exec_cmd([[cliphist list | rofi -dmenu | cliphist decode | wl-copy]]))
      hl.bind(mod .. " + SHIFT + S",  hl.dsp.exec_cmd([[grim -g "$(slurp)" -t png | wl-copy]]))
      hl.bind(mod .. " + SHIFT + H",  hl.dsp.exec_cmd([[rofi -modi "keybinds:hypr-keybinds" -show keybinds -p " Keybinds"]]))
      hl.bind(mod .. " + SHIFT + SPACE", hl.dsp.exec_cmd([[pkill waybar || waybar]]))

      -- Move focus with arrow keys
      hl.bind(mod .. " + left",  hl.dsp.focus({ direction = "left" }))
      hl.bind(mod .. " + right", hl.dsp.focus({ direction = "right" }))
      hl.bind(mod .. " + up",    hl.dsp.focus({ direction = "up" }))
      hl.bind(mod .. " + down",  hl.dsp.focus({ direction = "down" }))

      -- Switch workspaces (mod + [0-9]) and move active window (mod + SHIFT + [0-9]).
      -- 10 maps to key 0.
      for i = 1, 10 do
        local key = i % 10
        hl.bind(mod .. " + " .. key,         hl.dsp.focus({ workspace = i }))
        hl.bind(mod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
      end

      -- Scrolling
      hl.bind(mod .. " + K",         hl.dsp.layout("focus r"))
      hl.bind(mod .. " + J",         hl.dsp.layout("focus l"))
      hl.bind(mod .. " + SHIFT + K", hl.dsp.layout("swapcol r"))
      hl.bind(mod .. " + SHIFT + J", hl.dsp.layout("swapcol l"))
      hl.bind(mod .. " + comma",     hl.dsp.layout("colresize -0.2"))
      hl.bind(mod .. " + period",    hl.dsp.layout("colresize +0.2"))

      -- Swap active window with the one next to it
      hl.bind(mod .. " + SHIFT + LEFT",  hl.dsp.window.swap({ direction = "l" }))
      hl.bind(mod .. " + SHIFT + RIGHT", hl.dsp.window.swap({ direction = "r" }))
      hl.bind(mod .. " + SHIFT + UP",    hl.dsp.window.swap({ direction = "u" }))
      hl.bind(mod .. " + SHIFT + DOWN",  hl.dsp.window.swap({ direction = "d" }))

      -- Cycle through windows in the active workspace
      hl.bind("ALT + TAB",         hl.dsp.window.cycle_next({ next = true }))
      hl.bind("ALT + SHIFT + TAB", hl.dsp.window.cycle_next({ next = false }))

      -- Special workspace (scratchpad)
      -- hl.bind(mod .. " + S",         hl.dsp.workspace.toggle_special("magic"))
      -- hl.bind(mod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

      -- Print screen key
      hl.bind("PRINT", hl.dsp.exec_cmd([[grim -g "$(slurp)" -t png | wl-copy]]))

      -- Volume
      hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd([[wpctl set-volume @DEFAULT_SINK@ 5%+ && notify-send -h string:x-canonical-private-synchronous:volume "Volume" "$(wpctl get-volume @DEFAULT_SINK@ | awk '{printf "%d%%", $2 * 100}')" -t 1500]]))
      hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd([[wpctl set-volume @DEFAULT_SINK@ 5%- && notify-send -h string:x-canonical-private-synchronous:volume "Volume" "$(wpctl get-volume @DEFAULT_SINK@ | awk '{printf "%d%%", $2 * 100}')" -t 1500]]))
      hl.bind("XF86AudioMute", hl.dsp.exec_cmd([[wpctl set-mute @DEFAULT_SINK@ toggle && notify-send -h string:x-canonical-private-synchronous:volume "Volume" "$(wpctl get-volume @DEFAULT_SINK@)" -t 1500]]))
      hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd([[wpctl set-mute @DEFAULT_SOURCE@ toggle && notify-send -h string:x-canonical-private-synchronous:mic "Microphone" "$(wpctl get-volume @DEFAULT_SOURCE@ | grep -q MUTED && echo 'Muted' || echo 'Unmuted')" -t 1500]]))

      -- Brightness
      hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd([[brightnessctl set +10% && notify-send -h string:x-canonical-private-synchronous:brightness "Brightness" "$(brightnessctl get)% / $(brightnessctl max)%" -t 1500]]))
      hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd([[brightnessctl set 10%- && notify-send -h string:x-canonical-private-synchronous:brightness "Brightness" "$(brightnessctl get)% / $(brightnessctl max)%" -t 1500]]))

      -- Resize active window ("code:20" = - key, "code:21" = = key)
      hl.bind(mod .. " + code:20",         hl.dsp.window.resize({ x = -100, y = 0, relative = true }))
      hl.bind(mod .. " + code:21",         hl.dsp.window.resize({ x = 100, y = 0, relative = true }))
      hl.bind(mod .. " + SHIFT + code:20", hl.dsp.window.resize({ x = 0, y = -100, relative = true }))
      hl.bind(mod .. " + SHIFT + code:21", hl.dsp.window.resize({ x = 0, y = 100, relative = true }))

      -- Scroll through existing workspaces
      hl.bind(mod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
      hl.bind(mod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))
      hl.bind(mod .. " + TAB",        hl.dsp.focus({ workspace = "e+1" }))

      -- Move/resize windows with mod + LMB/RMB and dragging
      hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
      hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })
    '';
  };
}
