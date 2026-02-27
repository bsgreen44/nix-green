{ pkgs, username, ... }:

{
  # Hyprland packages
  home.packages = with pkgs; [
    brightnessctl
    dunst        # notifications
    grim         # screenshot
    slurp        # screenshot
    wl-clipboard
    swaybg       # wallpaper config
    swayimg      # Image viewer
    thunar       # GUI file manager
  ];
  
  # clipboard manager
  services.cliphist.enable = true;

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
    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
    };
  };

  # Hyprland configuration
  wayland.windowManager.hyprland = {
    enable = true;
    settings = {
      group = {
        groupbar = {
          font_family = "JetBrainsMono Nerd Font";
          font_size = 10;
        };
      };
    };

    # Use extraConfig for raw configuration instead of settings
    extraConfig = ''
      $terminal = ghostty
      $mod = SUPER
      $menu = rofi -show drun -show-icons -display-drun ""
      $browser = brave

      # Monitor configuration
      monitor=,preferred,auto,1

      # Cursor configuration
      cursor {
          no_hardware_cursors = true
      }

      # Autostart
      exec-once = waybar
      exec-once = dunst
      exec-once = wl-paste --type text --watch cliphist store 
      exec-once = wl-paste --type image --watch cliphist store
      exec = swaybg -i /home/${username}/nix-green/wallpapers/nix-wallpaper-nineish-catppuccin-frappe-alt.png -m fill


      # Input configuration
      input {
          kb_layout = us
          follow_mouse = 1
          sensitivity = 0
          
          touchpad {
              natural_scroll = no
          }
      }

      # General settings
      general {
          gaps_in = 3
          gaps_out = 7
          border_size = 2
          col.active_border = rgba(33ccffee) rgba(00ff99ee) 45deg
          col.inactive_border = rgba(595959aa)
          layout = dwindle
      }

      # Decorations
      decoration {
          rounding = 8
          
          blur {
              enabled = yes
              size = 3
              passes = 1
          }
          
          shadow {
              enabled = true
              range = 4
              render_power = 3
              color = rgba(1a1a1aee)
          }
      }

      # Animations
      animations {
          enabled = yes
          
          bezier = myBezier, 0.05, 0.9, 0.1, 1.05
          
          animation = windows, 1, 7, myBezier
          animation = windowsOut, 1, 7, default, popin 80%
          animation = border, 1, 10, default
          animation = borderangle, 1, 8, default
          animation = fade, 1, 7, default
          animation = workspaces, 1, 6, default
      }

      # Layout
      dwindle {
          pseudotile = yes
          preserve_split = yes
      }

      # Master layout (alternative)
      master {
          new_status = master
      }

      # Window rules
      windowrule = match:class ^(swayimg)$, float on
      windowrule = match:class ^(swayimg)$, center on

      #### doesn't work
      windowrule = match:class ^(com.mitchellh.ghostty)$, match:title ^(btop)$, float on
      windowrule = match:class ^(com.mitchellh.ghostty)$, match:title ^(btop)$, center on

      # ---Keybindings

      # Application launchers
      bind = $mod, Return, exec, $terminal
      bind = $mod SHIFT, B, exec, $browser
      bind = $mod SHIFT, F, exec, thunar
      bind = $mod SHIFT, O, exec, obsidian
      bind = $mod SHIFT, V, exec, code
      bind = $mod SHIFT, M, exec, $terminal -e btop
      bind = $mod SHIFT, T, exec, $terminal -e sudo tsui
      bind = $mod SHIFT, N, exec, $terminal -e nvim
      bind = $mod SHIFT, L, exec, $terminal -e lazygit
      bind = $mod, Q, killactive,
      bind = $mod SHIFT, ESCAPE, exit,
      bind = $mod, T, togglefloating,
      bind = $mod, SPACE, exec, $menu
      bind = $mod, P, pseudo,
      bind = $mod, J, togglesplit,
      bind = $mod, F, fullscreen,
      bind = $mod, L, exec, hyprlock
      bind = $mod CTRL, V, exec, cliphist list | rofi -dmenu | cliphist decode | wl-copy

      # Move focus with arrow keys
      bind = $mod, left, movefocus, l
      bind = $mod, right, movefocus, r
      bind = $mod, up, movefocus, u
      bind = $mod, down, movefocus, d

      # Move focus with vim keys
      bind = $mod, h, movefocus, l
      bind = $mod, l, movefocus, r
      bind = $mod, k, movefocus, u
      bind = $mod, j, movefocus, d

      # Switch workspaces
      bind = $mod, 1, workspace, 1
      bind = $mod, 2, workspace, 2
      bind = $mod, 3, workspace, 3
      bind = $mod, 4, workspace, 4
      bind = $mod, 5, workspace, 5
      bind = $mod, 6, workspace, 6
      bind = $mod, 7, workspace, 7
      bind = $mod, 8, workspace, 8
      bind = $mod, 9, workspace, 9
      bind = $mod, 0, workspace, 10

      # Move active window to workspace
      bind = $mod SHIFT, 1, movetoworkspace, 1
      bind = $mod SHIFT, 2, movetoworkspace, 2
      bind = $mod SHIFT, 3, movetoworkspace, 3
      bind = $mod SHIFT, 4, movetoworkspace, 4
      bind = $mod SHIFT, 5, movetoworkspace, 5
      bind = $mod SHIFT, 6, movetoworkspace, 6
      bind = $mod SHIFT, 7, movetoworkspace, 7
      bind = $mod SHIFT, 8, movetoworkspace, 8
      bind = $mod SHIFT, 9, movetoworkspace, 9
      bind = $mod SHIFT, 0, movetoworkspace, 10

      # Swap active window with the one next to it
      bind = $mod SHIFT, LEFT, swapwindow, l
      bind = $mod SHIFT, RIGHT, swapwindow, r
      bind = $mod SHIFT, UP, swapwindow, u
      bind = $mod SHIFT, DOWN, swapwindow, d

      # Cycle through windows in active worksapce
      bind = ALT, TAB, cyclenext
      bind = ALT SHIFT, TAB, cyclenext, prev

      # Special workspace (scratchpad)
      bind = $mod, S, togglespecialworkspace, magic
      bind = $mod SHIFT, S, movetoworkspace, special:magic

      # Function keys
      bind = , XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_SINK@ 5%+
      bind = , XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_SINK@ 5%-
      bind = , XF86MonBrightnessUp, exec, brightnessctl set +10%
      bind = , XF86MonBrightnessDown, exec, brightnessctl set 10%-
      bind = , XF86AudioMute, exec, wpctl set-mute @DEFAULT_SINK@ toggle
      bind = , XF86AudioMicMute, exec, wpctl set-mute @DEFAULT_SOURCE@ toggle
      bind = , PRINT, exec, grim -g "$(slurp)" -t png | wl-copy

      # Resize active window
      bind = $mod, code:20, resizeactive, -100 0    # - key
      bind = $mod, code:21, resizeactive, 100 0     # = key
      bind = $mod SHIFT, code:20, resizeactive, 0 -100
      bind = $mod SHIFT, code:21, resizeactive, 0 100

      # Scroll through existing workspaces
      bind = $mod, mouse_down, workspace, e+1
      bind = $mod, mouse_up, workspace, e-1

      # Move/resize windows with mod + LMB/RMB and dragging
      bindm = $mod, mouse:272, movewindow
      bindm = $mod, mouse:273, resizewindow
    '';
  };
}
