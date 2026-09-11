{ pkgs, lib, config, ... }:

let
  # Role registry: the screensaver is a full-screen window of whatever terminal
  # this machine uses, and the pkill patterns below have to match it.
  term = config.green.apps.terminal.command;

  # On-demand screensaver. With `--lock` (idle use) it also arms a timer that
  # locks the session and turns the display off after 120s; without it the
  # animation just runs until a key is pressed.
  screensaver = pkgs.writeShellScriptBin "screensaver" ''
    # Don't launch over the lock screen
    pgrep -x hyprlock > /dev/null && exit 0

    # `--lock` (idle use): after 120s, lock + close screensaver + display off
    if [ "''${1:-}" = "--lock" ]; then
      ( sleep 120 \
          && loginctl lock-session \
          && pkill -f "${term}.*title=full" \
          && sleep 2 \
          && hyprctl dispatch dpms off ) &
      TIMER_PID=$!
    fi

    ${term} --title=full --font-size=29 -e sh -c '
      ( while true; do
          cols=$(tput cols); rows=$(tput lines)
          COLS=$cols ROWS=$rows ${pkgs.python3Minimal}/bin/python3 $HOME/.local/share/center_logo.py \
            | tte --canvas-width $cols --canvas-height $rows --random-effect
        done ) & LOOP_PID=$!
      read -n 1 -s
      kill $LOOP_PID 2>/dev/null
    '

    # Reached when the terminal exits (keypress, or killed by the timer)
    [ -n "''${TIMER_PID:-}" ] && kill "$TIMER_PID" 2>/dev/null
    pkill -f "${term}.*title=full"
  '';
in
{
  ## The idle screensaver is a toggle rather than a commented-out hypridle
  ## listener. modules/hypridle.nix reads this to pick what the 3-minute idle
  ## timeout runs; the option lives here because this file owns the script.
  options.green.screensaver.enable = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = ''
      Run the screensaver when the session goes idle. When false, hypridle's
      3-minute listener locks the session directly instead. Either way the
      `screensaver` command and its SUPER + SHIFT + Z bind stay available for
      manual use.
    '';
  };

  config = {
    home.packages = [ screensaver ];

    # Edit this to customize tte screensaver
    home.file.".local/share/logo.txt".text = ''
            ▗▄▄▄       ▗▄▄▄▄    ▄▄▄▖
            ▜███▙       ▜███▙  ▟███▛
             ▜███▙       ▜███▙▟███▛
              ▜███▙       ▜██████▛
       ▟█████████████████▙ ▜████▛     ▟▙
      ▟███████████████████▙ ▜███▙    ▟██▙
             ▄▄▄▄▖           ▜███▙  ▟███▛
            ▟███▛             ▜██▛ ▟███▛
           ▟███▛               ▜▛ ▟███▛
  ▟███████████▛                  ▟██████████▙
  ▜██████████▛                  ▟███████████▛
        ▟███▛ ▟▙               ▟███▛
       ▟███▛ ▟██▙             ▟███▛
      ▟███▛  ▜███▙           ▝▀▀▀▀
      ▜██▛    ▜███▙ ▜██████████████████▛
       ▜▛     ▟████▙ ▜████████████████▛
             ▟██████▙         ▜███▙
            ▟███▛▜███▙         ▜███▙
           ▟███▛  ▜███▙         ▜███▙
           ▝▀▀▀    ▀▀▀▀▘         ▀▀▀▘
    '';

    # This centers the logo
    home.file.".local/share/center_logo.py".text = ''
    import unicodedata, os

    def wcswidth(s):
        w = 0
        for c in s:
            e = unicodedata.east_asian_width(c)
            w += 2 if e in ('W', 'F') else 1
        return w

    cols = int(os.environ.get("COLS", 80))
    rows = int(os.environ.get("ROWS", 24))

    lines = open(os.path.expanduser("~/.local/share/logo.txt")).read().splitlines()
    lines = [l for l in lines if l.strip()]  # Remove empty lines
    max_w = max(wcswidth(l) for l in lines)

    top_pad = max(0, (rows - len(lines)) // 2)
    bottom_pad = max(0, rows - len(lines) - top_pad)
    left_pad = max(0, (cols - max_w) // 2)

    print("\n" * top_pad, end="")

    for l in lines:
        print(" " * left_pad + l)
    print("\n" * bottom_pad, end="")
    '';
  };
}
