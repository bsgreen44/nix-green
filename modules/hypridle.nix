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
          on-timeout = ''ghostty --title=full --font-size=25 -e sh -c "( sleep 120 && loginctl lock-session && pkill -f 'ghostty.*title=full' && sleep 2 && hyprctl dispatch dpms off && sleep 1080 && systemctl suspend ) & TIMER_PID=\$!; ( while true; do cols=\$(tput cols); rows=\$(tput lines); COLS=\$cols python3 \$HOME/.local/share/center_logo.py | tte --canvas-width \$cols --canvas-height \$rows --random-effect; done ) & LOOP_PID=\$!; read -n 1 -s; kill \$LOOP_PID 2>/dev/null; kill \$TIMER_PID 2>/dev/null; pkill -f 'ghostty.*title=full'"'';
        }
        #{
        #  timeout = 180; # 3 minutes
        #  on-timeout = "loginctl lock-session"; # Lock screen
        #}
        #{
        #  timeout = 330; # 5.5 minutes
        #  on-timeout = "hyprctl dispatch dpms off"; # Screen off
        #  on-resume = "hyprctl dispatch dpms on"; # Screen on
        #}
        #{
        #  timeout = 1800; # 30 minutes
        #  on-timeout = "systemctl suspend"; # Suspend PC
        #}
      ];
    };
  };
}
