{ config, ... }:

let
  # 3 minutes: either the screensaver (which arms its own 120s lock timer, so the
  # session locks at ~5 minutes - see modules/screensaver.nix) or a straight lock.
  # Flip `green.screensaver.enable` to choose; the manual SUPER + SHIFT + Z
  # screensaver bind works either way.
  idleAction =
    if config.green.screensaver.enable
    then "screensaver --lock"
    else "loginctl lock-session";
in
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
          timeout = 180; # 3 minutes: screensaver, or lock if it's disabled
          on-timeout = idleAction;
        }
        {
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
