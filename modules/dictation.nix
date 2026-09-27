{ pkgs, lib, ... }:

let
  # Pinned in the store rather than downloaded on first use, so dictation works
  # offline from the first run and every machine gets the same model.
  # base.en: ~1-2s per 10s clip on a laptop CPU; small.en is the next step up.
  model = pkgs.fetchurl {
    url = "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.en.bin";
    hash = "sha256-oDd5yG3zMjB19eeWyyzlAp8A7Ihp7uP9+4l6/jbG0AI=";
  };

  # Voice activity detection, so only speech reaches the model. Without it
  # whisper hallucinates on silence ("you", "Thank you.") and a press-press
  # with nothing said types that into the focused window.
  vadModel = pkgs.fetchurl {
    url = "https://huggingface.co/ggml-org/whisper-vad/resolve/main/ggml-silero-v5.1.2.bin";
    hash = "sha256-KZQNmNQrkfvQXOSJ8+z3xy8KQvAn5IdZGaKPtMBOos8=";
  };

  # Toggle: the first call starts recording, the second stops it, transcribes
  # locally with whisper.cpp, copies the text and types it into the focused
  # window. Typing needs the virtual-keyboard protocol (Hyprland and other
  # wlroots compositors); where it is missing (KWin, Mutter) the clipboard
  # copy is the result. Bound per desktop - see the SUPER + D bind in
  # hyprland.nix; elsewhere bind `dictation` in the DE's shortcut settings.
  dictation = pkgs.writeShellApplication {
    name = "dictation";
    runtimeInputs = with pkgs; [
      whisper-cpp
      pipewire   # pw-record; speaks the socket protocol, so the distro daemon is fine
      wtype
      wl-clipboard
      libnotify
      coreutils
      gnused
    ];
    text = ''
      state="''${XDG_RUNTIME_DIR:-/tmp}/dictation"
      pidfile="$state/pid"
      audio="$state/audio.wav"
      idfile="$state/notify-id"
      mkdir -p "$state"

      # One notification updated in place: Recording -> Transcribing -> result.
      # Never fatal, so a session without a notification daemon still works.
      notify() {
        local id
        id=$(cat "$idfile" 2>/dev/null || echo 0)
        notify-send -a Dictation -p -r "$id" "$@" > "$idfile" 2>/dev/null || true
      }

      if [[ -f $pidfile ]] && kill -0 "$(cat "$pidfile")" 2>/dev/null; then
        pid=$(cat "$pidfile")
        rm -f "$pidfile"
        trap 'rm -f "$audio" "$idfile" "$state/record.log"' EXIT

        # pw-record finalizes the WAV header on SIGINT, so wait for it to exit
        kill -INT "$pid"
        for _ in $(seq 100); do
          kill -0 "$pid" 2>/dev/null || break
          sleep 0.05
        done

        notify -t 0 "Dictation" "Transcribing..."
        # Drop whisper's non-speech annotations ([BLANK_AUDIO], (wind blowing))
        # and join its line breaks into one line of text
        if ! text=$(whisper-cli -m ${model} -f "$audio" -t "$(nproc)" -nt -np -sns --vad -vm ${vadModel} 2>/dev/null \
          | sed -E 's/\[[^]]*\]//g; s/\([^)]*\)//g' \
          | tr '\n' ' ' \
          | sed -E 's/[[:space:]]+/ /g; s/^ //; s/ $//'); then
          notify -u critical -t 5000 "Dictation" "Transcription failed"
          exit 1
        fi

        if [[ -z $text ]]; then
          notify -t 2000 "Dictation" "No speech detected"
          exit 0
        fi

        wl-copy -- "$text"
        if printf '%s' "$text" | wtype - 2>/dev/null; then
          notify -t 1500 "Dictation" "Typed and copied"
        else
          notify -t 3000 "Dictation" "Copied to clipboard"
        fi
      else
        rm -f "$audio" "$idfile"
        pw-record --rate 16000 --channels 1 --format s16 "$audio" 2> "$state/record.log" &
        pid=$!

        # With no input device pw-record exits at once ("no target node
        # available"); say so instead of showing a recording that isn't one
        sleep 0.3
        if ! kill -0 "$pid" 2>/dev/null; then
          rm -f "$audio"
          notify -u critical -t 5000 "Dictation" "Could not record: $(head -n 1 "$state/record.log")"
          rm -f "$idfile"
          exit 1
        fi

        echo "$pid" > "$pidfile"
        notify -t 0 "Dictation" "Recording... press again to stop"
      fi
    '';
  };
in
{
  # Linux-only for now (pw-record, wl-clipboard, wtype)
  config = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
    home.packages = [ dictation ];
  };
}
