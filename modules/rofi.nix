{ pkgs, config, ... }:

{
  xdg.desktopEntries = {
    hyprmon = {
      name = "HyprMon";
      genericName = "Monitor Manager";
      exec = "ghostty -e hyprmon";
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
          margin = mkLiteral "10px 0px 0px 20px";
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
          text-color = mkLiteral "@blue";
        };
      };
  };
}
