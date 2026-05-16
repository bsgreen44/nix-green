{ pkgs, config, lib, ... }:

let
  keybindsScript = pkgs.writeShellScriptBin "hypr-keybinds" ''
    cat <<'EOF'
Super + Return               →  Terminal (ghostty)
Super + Shift + B            →  Browser (brave)
Super + Shift + F            →  File manager (thunar)
Super + Shift + O            →  Obsidian
Super + Shift + V            →  VS Code
Super + Shift + N            →  Neovim
Super + Shift + G            →  Lazygit
Super + Shift + A            →  opencode
Super + Shift + M            →  btop
Super + Shift + T            →  Tailscale
Super + Shift + SPACE        →  Hide Waybar
Super + Space                →  App launcher
Super + Q                    →  Close window
Super + T                    →  Toggle floating
Super + F                    →  Fullscreen
Super + P                    →  Pseudotile
Super + U                    →  Toggle split
Super + Shift + Esc          →  Exit Hyprland
Super + ←/→/↑/↓              →  Focus direction
Super + Shift + ←/→/↑/↓      →  Swap window
Alt + Tab                    →  Cycle windows
Alt + Shift + Tab            →  Cycle windows (back)
Super + K                    →  Focus column right
Super + J                    →  Focus column left
Super + Shift + K            →  Swap column right
Super + Shift + J            →  Swap column left
Super + ,                    →  Shrink column
Super + .                    →  Grow column
Super + 1–9                  →  Switch workspace
Super + 0                    →  Switch workspace 10
Super + Shift + 1–9          →  Move to workspace
Super + Tab                  →  Next workspace
Super + -                    →  Shrink window width
Super + =                    →  Grow window width
Super + Shift + -            →  Shrink window height
Super + Shift + =            →  Grow window height
Super + L                    →  Lock screen
Super + Esc                  →  Power menu
Super + Ctrl + V             →  Clipboard history
Super + Shift + S            →  Screenshot to clipboard
Print                        →  Screenshot to clipboard
Vol Up/Down                  →  Volume ±5%
Mute                         →  Toggle mute
Brightness Up/Down           →  Brightness ±10%
EOF
  '';
in
{
  home.packages = [ keybindsScript ];

  xdg.desktopEntries = {
    hyprmon = {
      name = "HyprMon";
      genericName = "Monitor Manager";
      exec = "ghostty --title=float -e hyprmon";
      terminal = false;
      categories = [ "System" "Settings" ];
      icon = "video-display";
    };
    nvim = {
      name = "Neovim";
      genericName = "Text Editor";
      exec = "ghostty -e nvim %F";
      terminal = false;
      categories = [ "Utility" "TextEditor" ];
      mimeType = [ "text/plain" "text/markdown" ];
      icon = "nvim";
    };
    tsui = {
      name = "Tailscale";
      genericName = "Tailscale TUI";
      exec = "ghostty --title=float -e sudo tsui";
      terminal = false;
      categories = [ "System" "Network" ];
      icon = "network-wireless-encrypted";
    };
  };

  programs.rofi = {
    enable = true;
    package = pkgs.rofi;
    font = "JetBrainsMono Nerd Font 12";
    terminal = "${pkgs.ghostty}/bin/ghostty";
  
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
          bg-col = mkLiteral "#1e1e2e";
          bg-col-light = mkLiteral "#8181cfff";
          border-col = mkLiteral "#9d9df0ff";
          blue = mkLiteral "#89b4fa";
          fg-col = mkLiteral "#cdd6f4";
          grey = mkLiteral "#6c7086";

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
