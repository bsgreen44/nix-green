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

      background-color = "#eff1f5";
      text-color = "#4c4f69";
      border-color = "#8839ef";
      border-size = 2;
      border-radius = 8;
      padding = "8";
      margin = "6";
      width = 400;

      # Progress bar color
      progress-color = "over #8839ef";
    };
  };
}