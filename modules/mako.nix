{ ... }:

{
  services.mako = {
    enable = true;
    settings = {
      icons = true;
      max-visible = 5;
      sort = "-time";
      layer = "overlay";
      anchor = "top-right";
      default-timeout = 5000;
      font = "JetBrainsMono Nerd Font 10";

      background-color = "#1e1e2e";
      text-color = "#cdd6f4";
      border-color = "#313244";
      border-size = 2;
      border-radius = 8;
      padding = "8";
      margin = "6";
      width = 400;

      # Progress bar color
      progress-color = "over #1e1e2e";
    };

    # Urgency levels and other overrides go in extraConfig as raw INI
    extraConfig = ''
      [urgency=low]
      background-color=#1e1e2e
      text-color=#a6e3a1
      border-color=#a6e3a1

      [urgency=normal]
      background-color=#1e1e2e
      text-color=#89b4fa
      border-color=#89b4fa

      [urgency=high]
      background-color=#1e1e2e
      text-color=#fab387
      border-color=#fab387

      [urgency=critical]
      background-color=#1e1e2e
      text-color=#f38ba8
      border-color=#f38ba8
    '';
  };
}