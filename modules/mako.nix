{ palette, ... }:

{
  services.mako = {
    enable = true;
    settings = {
      icons = true;
      max-visible = 5;
      sort = "-time";
      layer = "overlay";
      anchor = "top-right";
      font = "JetBrainsMono Nerd Font 10";

      # Apps are allowed to request "never expire" (expire_timeout=0); some do it
      # for every notification and the popup then sticks until it is clicked.
      # ignore-timeout makes mako use default-timeout for everything instead.
      default-timeout = 5000;
      ignore-timeout = true;

      # Keep dismissed notifications recoverable with `makoctl restore`.
      history = true;
      max-history = 25;

      # Catppuccin Mocha, semi-transparent background (#RRGGBBAA - cc ≈ 80% opaque).
      background-color = "#${palette.base}cc";
      text-color = "#${palette.text}";
      border-color = "#${palette.mauve}";
      progress-color = "over #${palette.surface0}cc";
      border-size = 2;
      border-radius = 8;
      padding = "8";
      margin = "6";
      width = 400;

      # Criteria (rendered as [section] blocks, applied on top of the above).
      "urgency=low" = {
        border-color = "#${palette.blue}";
        text-color = "#${palette.subtext0}";
        default-timeout = 3000;
      };

      "urgency=critical" = {
        border-color = "#${palette.red}";
        background-color = "#${palette.base}e6"; # more opaque so it stays readable
        # Critical still lingers noticeably longer, but it does go away on its own.
        default-timeout = 20000;
      };

      # The "(N more)" placeholder shown once max-visible is reached.
      "hidden" = {
        format = "<i>(%h more)</i>";
        text-color = "#${palette.subtext0}";
      };
    };
  };
}
