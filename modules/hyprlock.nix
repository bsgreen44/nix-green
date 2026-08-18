{ wallpaper, palette, ... }:

{
  programs.hyprlock = {
    enable = true;

    settings = {
      general = {
        # no_fade_in / grace / disable_loading_bar were removed upstream and are
        # rejected by 0.9.6. Show the lock surface without waiting for the
        # background to load, else the desktop stays visible for seconds.
        immediate_render = true;
      };

      background = [
        {
          path = "${wallpaper}";
          blur_passes = 3;
          blur_size = 8;
        }
      ];

      input-field = [
        {
          size = "250, 60";
          position = "0, -80";
          monitor = "";
          dots_center = true;
          fade_on_empty = false;
          font_color = "rgb(${palette.text})";
          inner_color = "rgb(${palette.base})";
          outer_color = "rgb(${palette.mauve})";
          outline_thickness = 5;
          # hyprlang treats a bare `#` as a comment, so the colour is doubled.
          placeholder_text = "<span foreground=\"##${palette.text}\">Password...</span>";
          shadow_passes = 2;
        }
      ];

      label = [
        # Time
        {
          text = "cmd[update:1000] echo \"$(date +'%H:%M')\"";
          color = "rgb(${palette.text})";
          font_size = 64;
          font_family = "JetBrainsMono Nerd Font";
          position = "0, 100";
          halign = "center";
          valign = "center";
        }
        # Date
        {
          text = "cmd[update:1000] echo \"$(date +'%A, %B %d')\"";
          color = "rgb(${palette.text})";
          font_size = 22;
          font_family = "JetBrainsMono Nerd Font";
          position = "0, 30";
          halign = "center";
          valign = "center";
        }
      ];
    };
  };
}
