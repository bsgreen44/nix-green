{ ... }:

{
  services.hypridle = {
    enable = true;

    settings = {
      general = {
        lock_cmd = "pidof hyprlock || hyprlock"; # Avoid starting multiple hyprlock instances
        before_sleep_cmd = "loginctl lock-session"; # Lock before suspend
        after_sleep_cmd = "hyprctl dispatch dpms on"; # Turn display on immediately after resume
      };

      listener = [
        {
          timeout = 150; # 2.5 minutes
          on-timeout = "brightnessctl -s set 10"; # Dim screen (requires brightnessctl)
          on-resume = "brightnessctl -r"; # Restore brightness
        }
        {
          # 3 minutes turn on screensaver.
          # After 5 minutes lock the screen and turn display off. After 20 minutes suspend
          timeout = 180;
          on-timeout = "screensaver --lock";
        }
        {
        #{
        #  timeout = 180; # 3 minutes
        #  on-timeout = "loginctl lock-session"; # Lock screen
        #}
          timeout = 330; # 5.5 minutes
          on-timeout = "hyprctl dispatch dpms off"; # Screen off
          on-resume = "hyprctl dispatch dpms on"; # Screen on
        }
        {
          timeout = 1200; # 20 minutes
          on-timeout = "systemctl suspend"; # Suspend PC
        }
      ];
    };
  };
}
