# `hyprland` is the flake input on NixOS, null where the distro installs the
# compositor. Must be supplied either way - the module system resolves declared
# args eagerly, so a `? null` default here would never apply.
{ pkgs, lib, config, wallpaper, hyprland, palette, ... }:

let
  apps = config.green.apps;

  # polkit_gnome's helper needs a setuid wrapper at /run/wrappers/bin, which
  # only exists on NixOS (security.wrappers). On the distro branch that path
  # is never created, so the nixpkgs build can never authenticate - same
  # class of bug as hyprlock.package = null in linux/hyprland.nix. Fedora's
  # own polkit-kde-authentication-agent-1 is already built against the real
  # setuid helper, so use that instead.
  polkitAgentCmd =
    if hyprland != null
    then "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1"
    else "/usr/libexec/kf6/polkit-kde-authentication-agent-1";

  # Floating utility windows, matched on Wayland app_id. The file manager and
  # calculator come from the role registry so a distro-provided app (dolphin,
  # kcalc) still lands in the float rule.
  floatClasses = [
    "gnome-disks"
    "com.nextcloud.desktopclient.nextcloud"
    apps.fileManager.class
    apps.calculator.class
  ];

  # Monitor profile editor and hotplug/lid daemon. Bumped past nixpkgs (1.9.1):
  # 1.10 verifies a Lua config by asking the running Hyprland rather than
  # parsing the include chain, which the pcall/dofile includes below defeat,
  # and 1.14 writes a file of its own instead of taking over monitors.lua.
  # Drop the override once nixpkgs catches up.
  hyprmoncfg = (pkgs.hyprmoncfg.override (lib.optionalAttrs (hyprland != null) {
    # hyprctl must match the running compositor.
    hyprland = hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
  })).overrideAttrs (finalAttrs: _: {
    version = "1.22.0";
    src = pkgs.fetchFromGitHub {
      owner = "crmne";
      repo = "hyprmoncfg";
      tag = "v${finalAttrs.version}";
      hash = "sha256-hrZZpyNk7jtJJXcEGP+DfzxfO1p4hn5ky3jc97ROR5Q=";
    };
    # Not scripts/capture-fixture, a screenshot tool for upstream's docs.
    # excludedPackages rather than subPackages, which would also skip the
    # internal/ tests.
    excludedPackages = [ "scripts/capture-fixture" ];
    # Tests write helper scripts with FHS shebangs the build sandbox lacks.
    # Rewritten wholesale: nixpkgs' per-file list (and upstream's own) goes
    # stale as tests are added.
    postPatch = ''
      grep -rlZ --include='*_test.go' -e '#!/bin/' -e '#!/usr/bin/env bash' . \
        | xargs -0 sed -i \
            -e 's|#!/bin/bash|#!${lib.getExe pkgs.bash}|g' \
            -e 's|#!/usr/bin/env bash|#!${lib.getExe pkgs.bash}|g' \
            -e 's|#!/bin/sh|#!${lib.getExe pkgs.bash}|g'
    '';
  } // lib.optionalAttrs (hyprland == null) {
    # Distro compositor: hyprctl comes from the session $PATH, the same as
    # hypr-workspace-layout-toggle. nixpkgs' wrapper would put its own
    # hyprctl first.
    postFixup = "";
  });

  # hyprmoncfg's generated rules. It would append the include to hyprland.lua
  # itself, but that is a read-only store path here, so the include is below.
  hyprmoncfgMonitors = ''(os.getenv("XDG_CONFIG_HOME") or os.getenv("HOME") .. "/.config") .. "/hypr/hyprmoncfg-monitors.lua"'';
in
{
  # Hyprland packages
  home.packages = with pkgs; [
    brightnessctl
    libnotify    # Provides the notify-send command
    mako         # notifications
    grim         # screenshot
    slurp        # screenshot
    wl-clipboard
    swaybg       # wallpaper; the unit below uses the store path, this is for manual use
    bibata-cursors
    rofi-power-menu
    hyprmoncfg   # monitor manager; rofi.nix has a desktop entry for it
  ]
  # NixOS only: on the distro branch the agent comes from the distro package
  # (polkit-kde), not nixpkgs - see polkitAgentCmd above.
  ++ lib.optional (hyprland != null) pkgs.polkit_gnome
  # Calculator and image viewer only when the role still points at a nixpkgs
  # package; a distro-provided dolphin/kcalc/gwenview sets package = null.
  ++ lib.optional (apps.calculator.package != null) apps.calculator.package
  ++ lib.optional (apps.imageViewer.package != null) apps.imageViewer.package;

  # clipboard manager
  services.cliphist.enable = true;

  # Low battery notifications via mako: normal urgency at the warning level,
  # mako's red urgency=critical style at the critical level. At the danger
  # level suspend instead of letting the laptop hard power-off.
  services.batsignal = {
    enable = true;
    extraArgs = [
      "-w" "20"
      "-c" "10"
      "-d" "3"
      "-D" "systemctl suspend"
      "-a" "Battery"
    ];
  };

  # Wallpaper. A unit and not an autostart exec_cmd, which fires once at login
  # and leaves the background bare if swaybg ever dies.
  systemd.user.services.swaybg = {
    Unit = {
      Description = "swaybg wallpaper daemon";
      ConditionEnvironment = "WAYLAND_DISPLAY";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.swaybg}/bin/swaybg -i ${wallpaper} -m fill";
      Restart = "always";
      # Short; systemd's start limit still fails the unit on an unreadable image.
      RestartSec = 1;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  # Applies the best matching hyprmoncfg profile on hotplug and lid changes.
  # Defined here rather than enabling the package's unit, which is wanted by
  # default.target and so would also manage monitors in a Plasma session.
  systemd.user.services.hyprmoncfgd = {
    Unit = {
      Description = "Hyprland monitor profile daemon (hyprmoncfgd)";
      PartOf = [ "hyprland-session.target" ];
      After = [ "hyprland-session.target" ];
    };
    Service = {
      ExecStart = "${hyprmoncfg}/bin/hyprmoncfgd";
      Restart = "on-failure";
      RestartSec = 2;
    };
    Install.WantedBy = [ "hyprland-session.target" ];
  };

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

    iconTheme.name = "breeze";
    cursorTheme = {
      name = "breeze_cursors";
      size = 24;
    };

    gtk2.configLocation = "${config.xdg.configHome}/gtk-2.0/gtkrc";

    gtk4.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
    };
    gtk4.theme = null;
    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
    };

    gtk3.extraCss = "/* Managed by Home Manager - deliberately no KDE colors.css import. */";
    gtk4.extraCss = "/* Managed by Home Manager - deliberately no KDE colors.css import. */";
  };

  # Hyprland configuration
  # package/portalPackage are set after the config block; both null when the
  # flake input is absent, so Nix writes hyprland.lua and defers to $PATH.
  wayland.windowManager.hyprland = {
    enable = true;
    configType = "lua";

    # Use extraConfig for raw Lua configuration (hl.* API) instead of the settings
    # attrset. Since Hyprland 0.55 hyprlang is deprecated in favor of Lua, so this
    # is emitted to ~/.config/hypr/hyprland.lua. See https://hypr.land/news/26_lua/
    extraConfig = lib.mkMerge [ ''
      local terminal  = "${apps.terminal.command}"
      local mod       = "SUPER"
      local menu      = [[rofi -show drun -show-icons -display-drun ""]]
      local browser   = "brave"
      local powermenu = [[rofi -show power-menu -theme-str 'inputbar { enabled: false; }' -theme-str 'window {width: 225px;}' -theme-str 'window {height: 260px;}' -modi "power-menu:rofi-power-menu"]]


      -- Fallback for displays no hyprmoncfg profile covers. Per-display mode,
      -- position and scale come from its profiles, loaded at the very end.
      hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })

      -- Per-machine overrides (keybinds, etc.), applied after the defaults
      -- above so they win. Monitor layouts belong to hyprmoncfg, whose rules
      -- load at the very end. With Lua the local override file is Lua too;
      -- dofile a missing file is a harmless no-op thanks to pcall.
      pcall(dofile, os.getenv("HOME") .. "/.config/hypr/local.lua")

      -- Cursor configuration
      hl.env("XCURSOR_THEME", "Bibata-Modern-Classic")
      hl.env("XCURSOR_SIZE", "20")
      hl.config({ cursor = { no_hardware_cursors = false } })

      -- Autostart
      -- cliphist, swaybg and waybar are omitted here: all run as user units
      -- already, and starting them twice double-stores every copy / stacks a
      -- second wallpaper / draws a second bar.
      hl.on("hyprland.start", function()
        hl.exec_cmd("pkill dunst; mako")
        -- Without an agent, polkit prompts fail silently (gnome-disks, nm).
        -- hyprpolkitagent was tried first but segfaults mid-authentication
        -- (hyprwm/hyprpolkitagent#45); see polkitAgentCmd above for the rest.
        hl.exec_cmd("${polkitAgentCmd}")
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

      -- General settings: layout is the default for every workspace (dwindle
      -- is also available as layout = "dwindle"). Per-workspace overrides are
      -- applied at runtime by modules/hypr-workspace-layout.nix, not pinned here.
      hl.config({
        general = {
          layout = "scrolling",
          gaps_in = 3,
          gaps_out = 7,
          border_size = 2,
          col = {
            active_border = { colors = { "rgba(${palette.mauve}ed)", "rgba(${palette.blue}ed)" }, angle = 45 },
            inactive_border = "rgba(595959aa)",
          },
        },
      })

      -- Hyprland scrolling (a core layout in Lua, no longer under plugin)
      hl.config({
        scrolling = {
          column_width = 0.5,
          fullscreen_on_one_column = true,
          -- Presets cycled by SUPER + R / SUPER + SHIFT + R (colresize +conf/-conf)
          explicit_column_widths = "0.333, 0.5, 0.667, 1.0",
        },
      })

      -- Decorations
      hl.config({
        decoration = {
          rounding = 8,
          -- Hyprland does the blurring for any transparent window (ghostty's own
          -- background-blur is KDE-only on Linux and is a no-op here).
          blur = {
            enabled = true,
            size = 8,
            passes = 3,
            new_optimizations = true,
            ignore_opacity = true,
          },
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
        match = { class = "^(${lib.concatStringsSep "|" floatClasses})$" },
        float = true,
        center = true,
        size = { 900, 600 },
      })

      hl.window_rule({
        name = "float-image-viewer",
        match = { class = "^(${apps.imageViewer.class})$" },
        float = true,
        center = true,
      })

      hl.window_rule({
        name = "float-title",
        match = { title = "^(float)$" },
        float = true,
        center = true,
        size = { 900, 600 },
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
      hl.bind(mod .. " + SHIFT + F",  hl.dsp.exec_cmd("${apps.fileManager.command}"))
      hl.bind(mod .. " + SHIFT + O",  hl.dsp.exec_cmd("obsidian"))
      hl.bind(mod .. " + SHIFT + V",  hl.dsp.exec_cmd("codium"))
      hl.bind(mod .. " + SHIFT + M",  hl.dsp.exec_cmd(terminal .. " --title=float -e btop"))
      hl.bind(mod .. " + SHIFT + T",  hl.dsp.exec_cmd(terminal .. " --title=float -e tsui"))
      hl.bind(mod .. " + SHIFT + N",  hl.dsp.exec_cmd(terminal .. " -e nvim"))
      hl.bind(mod .. " + SHIFT + G",  hl.dsp.exec_cmd(terminal .. " -e lazygit"))
      hl.bind(mod .. " + SHIFT + A",  hl.dsp.exec_cmd(terminal .. " -e opencode"))
      hl.bind(mod .. " + W",          hl.dsp.window.close())
      hl.bind(mod .. " + Q",          hl.dsp.window.close())
      hl.bind(mod .. " + SHIFT + ESCAPE", hl.dsp.exit())
      hl.bind(mod .. " + T",          hl.dsp.window.float({ action = "toggle" }))
      hl.bind(mod .. " + SPACE",      hl.dsp.exec_cmd(menu))
      hl.bind(mod .. " + P",          hl.dsp.window.pseudo())
      hl.bind(mod .. " + J",          hl.dsp.layout("togglesplit"))
      hl.bind(mod .. " + F",          hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))
      hl.bind(mod .. " + ALT + F",    hl.dsp.window.fullscreen({ mode = "maximized" }))
      -- routes through hypridle's guarded lock_cmd to avoid double hyprlock
      hl.bind(mod .. " + L",          hl.dsp.exec_cmd("loginctl lock-session"))
      -- Z = "zzz", manual screensaver
      hl.bind(mod .. " + SHIFT + Z",  hl.dsp.exec_cmd("screensaver"))
      hl.bind(mod .. " + ESCAPE",     hl.dsp.exec_cmd(powermenu))
      hl.bind(mod .. " + CTRL + V",   hl.dsp.exec_cmd([[cliphist list | rofi -dmenu | cliphist decode | wl-copy]]))
      hl.bind(mod .. " + SHIFT + S",  hl.dsp.exec_cmd([[grim -g "$(slurp)" -t png | wl-copy]]))
      -- Local Whisper dictation: press to record, press again to type the transcript
      hl.bind(mod .. " + D",          hl.dsp.exec_cmd("dictation"))
      hl.bind(mod .. " + K",          hl.dsp.exec_cmd([[rofi -modi "keybinds:hypr-keybinds" -show keybinds -p " Keybinds"]]))
      hl.bind(mod .. " + SHIFT + H",  hl.dsp.exec_cmd([[rofi -modi "keybinds:hypr-keybinds" -show keybinds -p " Keybinds"]]))
      -- Through systemd so a bar toggled back on is still supervised by the unit.
      hl.bind(mod .. " + SHIFT + SPACE", hl.dsp.exec_cmd([[systemctl --user is-active --quiet waybar && systemctl --user stop waybar || systemctl --user start waybar]]))
      -- Notifications: N dismisses the top one, CTRL+N clears the whole stack.
      hl.bind(mod .. " + N",         hl.dsp.exec_cmd("makoctl dismiss"))
      hl.bind(mod .. " + CTRL + N",  hl.dsp.exec_cmd("makoctl dismiss --all"))

      -- Move focus with arrow keys
      hl.bind(mod .. " + left",  hl.dsp.focus({ direction = "left" }))
      hl.bind(mod .. " + right", hl.dsp.focus({ direction = "right" }))
      hl.bind(mod .. " + up",    hl.dsp.focus({ direction = "up" }))
      hl.bind(mod .. " + down",  hl.dsp.focus({ direction = "down" }))

      -- Switch workspaces (mod + [0-9]) and move active window (mod + SHIFT + [0-9]).
      -- 10 maps to key 0.
      for i = 1, 10 do
        local key = i % 10
        hl.bind(mod .. " + " .. key,               hl.dsp.focus({ workspace = i }))
        hl.bind(mod .. " + SHIFT + " .. key,       hl.dsp.window.move({ workspace = i }))
        hl.bind(mod .. " + SHIFT + ALT + " .. key, hl.dsp.window.move({ workspace = i, follow = false }))
      end

      -- Flip the active workspace between dwindle and scrolling; persisted
      hl.bind(mod .. " + SHIFT + L", hl.dsp.exec_cmd("hypr-workspace-layout-toggle"))

      -- Scrolling layout: column width. Layout messages, so no-ops on dwindle.
      hl.bind(mod .. " + R",         hl.dsp.layout("colresize +conf"))
      hl.bind(mod .. " + SHIFT + R", hl.dsp.layout("colresize -conf"))
      hl.bind(mod .. " + comma",     hl.dsp.layout("colresize -0.1"))
      hl.bind(mod .. " + period",    hl.dsp.layout("colresize +0.1"))

      -- Move the active workspace to another monitor
      hl.bind(mod .. " + SHIFT + ALT + LEFT",  hl.dsp.workspace.move({ monitor = "l" }))
      hl.bind(mod .. " + SHIFT + ALT + RIGHT", hl.dsp.workspace.move({ monitor = "r" }))
      hl.bind(mod .. " + SHIFT + ALT + UP",    hl.dsp.workspace.move({ monitor = "u" }))
      hl.bind(mod .. " + SHIFT + ALT + DOWN",  hl.dsp.workspace.move({ monitor = "d" }))

      -- Swap active window with the one next to it
      hl.bind(mod .. " + SHIFT + LEFT",  hl.dsp.window.swap({ direction = "l" }))
      hl.bind(mod .. " + SHIFT + RIGHT", hl.dsp.window.swap({ direction = "r" }))
      hl.bind(mod .. " + SHIFT + UP",    hl.dsp.window.swap({ direction = "u" }))
      hl.bind(mod .. " + SHIFT + DOWN",  hl.dsp.window.swap({ direction = "d" }))

      -- Cycle through windows in the active workspace
      -- and raise it, so a floating window is not left hidden behind others
      hl.bind("ALT + TAB", function()
        hl.dispatch(hl.dsp.window.cycle_next({ next = true }))
        hl.dispatch(hl.dsp.window.bring_to_top())
      end)
      hl.bind("ALT + SHIFT + TAB", function()
        hl.dispatch(hl.dsp.window.cycle_next({ next = false }))
        hl.dispatch(hl.dsp.window.bring_to_top())
      end)

      -- Focus another monitor
      hl.bind("CTRL + ALT + TAB",         hl.dsp.focus({ monitor = "+1" }))
      hl.bind("CTRL + ALT + SHIFT + TAB", hl.dsp.focus({ monitor = "-1" }))

      -- Special workspace (scratchpad)
      hl.bind(mod .. " + S",       hl.dsp.workspace.toggle_special("scratchpad"))
      hl.bind(mod .. " + ALT + S", hl.dsp.window.move({ workspace = "special:scratchpad", follow = false }))

      -- Print screen key
      hl.bind("PRINT", hl.dsp.exec_cmd([[grim -g "$(slurp)" -t png | wl-copy]]))

      -- Volume and brightness
      hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd([[swayosd-client --output-volume=+5]]))
      hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd([[swayosd-client --output-volume=-5]]))
      hl.bind("XF86AudioMute",        hl.dsp.exec_cmd([[swayosd-client --output-volume mute-toggle]]))
      hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd([[swayosd-client --input-volume mute-toggle]]))
      hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd([[swayosd-client --brightness=+10]]))
      hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd([[swayosd-client --brightness=-10]]))

      -- Resize active window ("code:20" = - key, "code:21" = = key)
      hl.bind(mod .. " + code:20",         hl.dsp.window.resize({ x = -100, y = 0, relative = true }))
      hl.bind(mod .. " + code:21",         hl.dsp.window.resize({ x = 100, y = 0, relative = true }))
      hl.bind(mod .. " + SHIFT + code:20", hl.dsp.window.resize({ x = 0, y = -100, relative = true }))
      hl.bind(mod .. " + SHIFT + code:21", hl.dsp.window.resize({ x = 0, y = 100, relative = true }))

      -- Resize active window, finer steps
      hl.bind(mod .. " + ALT + code:20",         hl.dsp.window.resize({ x = -25, y = 0, relative = true }))
      hl.bind(mod .. " + ALT + code:21",         hl.dsp.window.resize({ x = 25, y = 0, relative = true }))
      hl.bind(mod .. " + SHIFT + ALT + code:20", hl.dsp.window.resize({ x = 0, y = -25, relative = true }))
      hl.bind(mod .. " + SHIFT + ALT + code:21", hl.dsp.window.resize({ x = 0, y = 25, relative = true }))

      -- Resize active window, coarser steps
      hl.bind(mod .. " + CTRL + code:20",         hl.dsp.window.resize({ x = -300, y = 0, relative = true }))
      hl.bind(mod .. " + CTRL + code:21",         hl.dsp.window.resize({ x = 300, y = 0, relative = true }))
      hl.bind(mod .. " + CTRL + SHIFT + code:20", hl.dsp.window.resize({ x = 0, y = -300, relative = true }))
      hl.bind(mod .. " + CTRL + SHIFT + code:21", hl.dsp.window.resize({ x = 0, y = 300, relative = true }))

      -- Scroll through existing workspaces
      hl.bind(mod .. " + mouse_down",  hl.dsp.focus({ workspace = "e+1" }))
      hl.bind(mod .. " + mouse_up",    hl.dsp.focus({ workspace = "e-1" }))
      hl.bind(mod .. " + TAB",         hl.dsp.focus({ workspace = "e+1" }))
      hl.bind(mod .. " + SHIFT + TAB", hl.dsp.focus({ workspace = "e-1" }))
      hl.bind(mod .. " + CTRL + TAB",  hl.dsp.focus({ workspace = "previous" }))

      -- Move/resize windows with mod + LMB/RMB and dragging
      hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
      hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

      -- Window grouping
      hl.bind(mod .. " + G",       hl.dsp.group.toggle())
      hl.bind(mod .. " + ALT + G", hl.dsp.window.move({ out_of_group = true }))

      hl.bind(mod .. " + ALT + LEFT",  hl.dsp.window.move({ into_group = "l" }))
      hl.bind(mod .. " + ALT + RIGHT", hl.dsp.window.move({ into_group = "r" }))
      hl.bind(mod .. " + ALT + UP",    hl.dsp.window.move({ into_group = "u" }))
      hl.bind(mod .. " + ALT + DOWN",  hl.dsp.window.move({ into_group = "d" }))

      hl.bind(mod .. " + ALT + TAB",         hl.dsp.group.next())
      hl.bind(mod .. " + ALT + SHIFT + TAB", hl.dsp.group.prev())

      hl.bind(mod .. " + CTRL + LEFT",  hl.dsp.group.prev())
      hl.bind(mod .. " + CTRL + RIGHT", hl.dsp.group.next())

      hl.bind(mod .. " + ALT + mouse_down", hl.dsp.group.next())
      hl.bind(mod .. " + ALT + mouse_up",   hl.dsp.group.prev())

      for index = 1, 5 do
        hl.bind(mod .. " + ALT + code:" .. tostring(index + 9), hl.dsp.group.active({ index = index }))
      end
    ''

    # After everything, including hypr-workspace-layout's mkAfter block: any
    # monitor rule read later would override the layout hyprmoncfg applied.
    (lib.mkOrder 2000 ''

      -- hyprmoncfg's generated monitor rules, last so the applied layout is
      -- final. The file holds whichever profile was applied last, so after
      -- undocking, a docked profile's disabled laptop panel comes back at the
      -- next login with nothing else connected: the screen stays frozen on the
      -- greeter's last frame, and an output disabled that early may not come
      -- back until Hyprland restarts. Its disable rules are therefore held
      -- back and applied only if some connected display stays on.
      local function guarded_dofile(path)
        local file = io.open(path, "r")
        if not file then return end
        file:close()

        -- The selector a rule disables, for both the table and the legacy
        -- string form hyprmoncfg writes.
        local function disabledOutput(rule)
          if type(rule) == "table" then
            return rule.disabled and rule.output or nil
          end
          return tostring(rule):match("^%s*([^,]-)%s*,%s*disable")
        end

        local monitor = hl.monitor
        local disables = {}
        hl.monitor = function(rule)
          if disabledOutput(rule) then disables[#disables + 1] = rule else monitor(rule) end
        end
        local ok, err = pcall(dofile, path)
        hl.monitor = monitor

        local function isDisabled(m)
          for _, rule in ipairs(disables) do
            local output = disabledOutput(rule)
            if output == m.name or output == "desc:" .. m.description then return true end
          end
          return false
        end

        -- get_monitors() omits outputs that are already off, and FALLBACK /
        -- HEADLESS-* are Hyprland's placeholders, not displays.
        local keepsOne = false
        for _, m in ipairs(hl.get_monitors()) do
          local virtual = m.name == "FALLBACK" or m.name:match("^HEADLESS") ~= nil
          if not virtual and not isDisabled(m) then keepsOne = true end
        end
        if keepsOne then
          for _, rule in ipairs(disables) do monitor(rule) end
        end

        if not ok then
          io.stderr:write("nix-green: hyprmoncfg monitor rules failed: " .. tostring(err) .. "\n")
        end
      end

      -- One line, in the shape `hyprmoncfg doctor` recognizes as its include
      -- (`do local`, `dofile(`, the generated file's name) when it checks
      -- that nothing loads after it.
      do local path = ${hyprmoncfgMonitors}; guarded_dofile(path) end
    '')
    ];
  }
  // (
    if hyprland != null then {
      # NixOS: build from the flake input, leave portalPackage at its default.
      package = hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
    } else {
      # Non-NixOS: compositor and portal come from the distro.
      package = null;
      portalPackage = null;
    }
  );
}
