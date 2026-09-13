{ pkgs, config, lib, palette, ... }:

let
  inherit (config.green.apps) terminal fileManager;

  # Interpolated from the role registry so the help can't drift from the binds.
  # The browser line stays literal, matching hyprland.nix's literal Lua local.
  keybindsScript = pkgs.writeShellScriptBin "hypr-keybinds" ''
    cat <<'EOF'
Super + Return                 →  Terminal (${terminal.command})
Super + Space                  →  App launcher (rofi)
Super + Shift + B              →  Browser (brave)
Super + Shift + F              →  File manager (${fileManager.command})
Super + Shift + O              →  Obsidian
Super + Shift + V              →  VSCodium
Super + Shift + N              →  Neovim
Super + Shift + G              →  Lazygit
Super + Shift + A              →  opencode
Super + Shift + M              →  btop
Super + Shift + T              →  Tailscale (tsui)
Super + W                      →  Close window
Super + Q                      →  Close window
Super + T                      →  Toggle floating
Super + F                      →  Fullscreen
Super + Alt + F                →  Full width (maximized)
Super + P                      →  Pseudotile
Super + J                      →  Toggle split
Super + ←/→/↑/↓                →  Focus direction
Super + Shift + ←/→/↑/↓        →  Swap window
Super + LMB drag               →  Move window
Super + RMB drag               →  Resize window
Alt + Tab                      →  Cycle windows / reveal on top
Alt + Shift + Tab              →  Cycle windows (back) / reveal on top
Ctrl + Alt + Tab               →  Focus next monitor
Ctrl + Alt + Shift + Tab       →  Focus previous monitor
Super + Shift + L              →  Toggle workspace layout (dwindle/scrolling)
Super + -                      →  Shrink window width
Super + =                      →  Grow window width
Super + Shift + -              →  Shrink window height
Super + Shift + =              →  Grow window height
Super + Alt + -                →  Shrink window width (fine)
Super + Alt + =                →  Grow window width (fine)
Super + Shift + Alt + -        →  Shrink window height (fine)
Super + Shift + Alt + =        →  Grow window height (fine)
Super + Ctrl + -               →  Shrink window width (coarse)
Super + Ctrl + =               →  Grow window width (coarse)
Super + Ctrl + Shift + -       →  Shrink window height (coarse)
Super + Ctrl + Shift + =       →  Grow window height (coarse)
Super + 1–9                    →  Switch workspace
Super + 0                      →  Switch workspace 10
Super + Shift + 1–9            →  Move to workspace
Super + Shift + 0              →  Move to workspace 10
Super + Shift + Alt + 1–9      →  Move to workspace silently
Super + Shift + Alt + 0        →  Move to workspace 10 silently
Super + Shift + Alt + ←/→/↑/↓  →  Move workspace to another monitor
Super + Tab                    →  Next workspace
Super + Shift + Tab            →  Previous workspace
Super + Ctrl + Tab             →  Former workspace
Super + Scroll                 →  Cycle workspaces
Super + S                      →  Toggle scratchpad
Super + Alt + S                →  Move window to scratchpad
Super + L                      →  Lock screen
Super + Shift + Z              →  Screensaver
Super + Esc                    →  Power menu
Super + Shift + Esc            →  Exit Hyprland
Super + Shift + Space          →  Toggle Waybar
Super + K                      →  Show this keybind list
Super + Shift + H              →  Show this keybind list
Super + Ctrl + V               →  Clipboard history
Super + Shift + S              →  Screenshot to clipboard
Print                          →  Screenshot to clipboard
Super + N                      →  Dismiss notification
Super + Ctrl + N               →  Dismiss all notifications
Vol Up/Down                    →  Volume ±5%
Mute                           →  Toggle mute
Mic Mute                       →  Toggle microphone mute
Brightness Up/Down             →  Brightness ±10%
Super + G                      →  Toggle window grouping
Super + Alt + G                →  Move window out of group
Super + Alt + ←/→/↑/↓          →  Move window into group (direction)
Super + Alt + Tab              →  Next window in group
Super + Alt + Shift + Tab      →  Previous window in group
Super + Ctrl + ←/→             →  Cycle grouped window focus
Super + Alt + Scroll           →  Cycle window in group
Super + Alt + 1–5              →  Switch to group window N
EOF
  '';
in
{
  home.packages = [ keybindsScript ];

  xdg.desktopEntries = {
    hyprmon = {
      name = "HyprMon";
      genericName = "Monitor Manager";
      exec = "${terminal.command} --title=float -e hyprmon";
      terminal = false;
      categories = [ "System" "Settings" ];
      icon = "video-display";
    };
    nvim = {
      name = "Neovim";
      genericName = "Text Editor";
      exec = "${terminal.command} -e nvim %F";
      terminal = false;
      categories = [ "Utility" "TextEditor" ];
      mimeType = [ "text/plain" "text/markdown" ];
      icon = "nvim";
    };
    tsui = {
      name = "Tailscale";
      genericName = "Tailscale TUI";
      # No sudo: tailscale's operator setting grants this user write access, and
      # sudo's secure_path can't see ~/.nix-profile/bin on non-NixOS distros.
      exec = "${terminal.command} --title=float -e tsui";
      terminal = false;
      categories = [ "System" "Network" ];
      icon = "network-wireless-encrypted";
    };
  };

  programs.rofi = {
    enable = true;
    package = pkgs.rofi;
    font = "JetBrainsMono Nerd Font 12";
    terminal = terminal.command;  # $PATH, not a store path: the distro build may be the real one
  
    extraConfig = {
      # This ensures that when you select a TUI app in 'drun', 
      # Rofi knows to wrap it in a terminal.
      run-shell-command = "{terminal} -e {cmd}";
  };

    theme =
      let
        # Use `mkLiteral` for values that should not be quoted in the generated .rasi file
        inherit (config.lib.formats.rasi) mkLiteral;
      in
      {
        "*" = {
          bg-col = mkLiteral "#${palette.base}";
          border-col = mkLiteral "#${palette.mauve}";
          blue = mkLiteral "#${palette.blue}";
          fg-col = mkLiteral "#${palette.text}";
          grey = mkLiteral "#${palette.overlay0}";

          background-color = mkLiteral "@bg-col";
          text-color = mkLiteral "@fg-col";
        };

        "window" = {
          height = mkLiteral "360px";
          width = mkLiteral "600px";
          border = mkLiteral "3px";
          border-color = mkLiteral "@border-col";
          background-color = mkLiteral "@bg-col";
          border-radius = mkLiteral "10px";
        };

        "mainbox" = {
          background-color = mkLiteral "@bg-col";
        };

        "inputbar" = {
          children = map mkLiteral [
            "prompt"
            "entry"
          ];
          background-color = mkLiteral "@bg-col";
          border-radius = mkLiteral "5px";
          padding = mkLiteral "2px";
        };

        "entry" = {
          padding = mkLiteral "6px";
          margin = mkLiteral "20px 0px 0px 10px";
          text-color = mkLiteral "@fg-col";
          background-color = mkLiteral "@bg-col";
          placeholder = "Search...";
          placeholder-color = mkLiteral "@grey";
        };

        "listview" = {
          border = mkLiteral "0px 0px 0px";
          padding = mkLiteral "6px 0px 0px";
          margin = mkLiteral "10px 20px 0px 20px";
          columns = 1;
          lines = 5;
          background-color = mkLiteral "@bg-col";
        };

        "element" = {
          padding = mkLiteral "5px";
          background-color = mkLiteral "@bg-col";
          text-color = mkLiteral "@fg-col";
        };

        "element-icon" = {
          size = mkLiteral "25px";
        };

        "element selected" = {
          background-color = mkLiteral "@blue";
        };
      };
  };
}
