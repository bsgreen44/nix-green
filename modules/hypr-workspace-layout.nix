{ pkgs, lib, config, ... }:

let
  # State the toggle writes and the Lua block below reads back on every config
  # load. One `<workspace>=<layout>` line per override, deliberately data rather
  # than the generated Lua omarchy stores: that makes the state directory an
  # execution path, and omarchy has had to permanently blocklist two of its own
  # state files over it (/usr/share/omarchy/default/hypr/toggles.lua).
  #
  # Interpolated at build time into both the writer and the reader, so the two
  # halves cannot disagree about the path. Omarchy re-derives it in bash and in
  # Lua and keeps them in sync by hand.
  stateDir = "${config.xdg.stateHome}/nix-green";
  stateFile = "${stateDir}/workspace-layouts";
in
{
  home.packages = [
    # writeShellApplication rather than writeShellScriptBin (the idiom in
    # rofi.nix and screensaver.nix): it runs shellcheck at build time and sets
    # `set -euo pipefail` for us, which is worth breaking consistency for on the
    # one script here that parses input and writes state.
    #
    # hyprctl is deliberately NOT in runtimeInputs: on NixOS it belongs to the
    # flake-built compositor, on other distros to the distro's, and only the
    # session $PATH knows which one is actually running. runtimeInputs only
    # prepends, so hyprctl still resolves normally.
    (pkgs.writeShellApplication {
      name = "hypr-workspace-layout-toggle";
      runtimeInputs = [ pkgs.jq pkgs.libnotify pkgs.coreutils pkgs.gnugrep ];
      text = ''
        active=$(hyprctl activeworkspace -j)
        workspace=$(jq -r '.id' <<< "$active")
        current=$(jq -r '.tiledLayout' <<< "$active")

        # Special workspaces get a dynamically assigned negative id, so a rule
        # keyed on one would restore onto an unrelated workspace after a
        # restart. Refuse rather than persist garbage; this is stricter than
        # omarchy's ^-?[0-9]+$ on purpose.
        if [[ ! $workspace =~ ^[1-9][0-9]*$ ]]; then
          notify-send -a hyprland -t 2000 "Workspace layout" "Not a regular workspace"
          exit 1
        fi

        # Anything that is not dwindle goes to dwindle, so a workspace sitting
        # on some third layout still converges instead of getting stuck.
        if [[ $current == dwindle ]]; then new=scrolling; else new=dwindle; fi

        # Apply before persisting, the reverse of omarchy's order: a failed
        # eval then leaves no state file promising a layout never applied.
        # `eval` runs Lua against the live config; the hyprlang keyword is the
        # fallback for a build predating it.
        #
        # Single-quoted Lua strings, so the shell string needs no backslashes
        # and nothing here depends on how Nix treats backslashes in an
        # indented string.
        hyprctl eval "hl.workspace_rule({ workspace = '$workspace', layout = '$new' })" >/dev/null 2>&1 ||
          hyprctl keyword workspace "$workspace, layout:$new" >/dev/null

        # Rewrite via a temp file in the same directory and rename, so a config
        # load racing the toggle reads either the whole old file or the whole
        # new one. One bad write would otherwise lose every override, not just
        # this workspace's.
        mkdir -p "${stateDir}"
        tmp=$(mktemp "${stateFile}.XXXXXX")
        trap 'rm -f "$tmp"' EXIT
        if [[ -f "${stateFile}" ]]; then
          grep -v "^$workspace=" "${stateFile}" >> "$tmp" || true
        fi
        printf '%s=%s\n' "$workspace" "$new" >> "$tmp"
        mv "$tmp" "${stateFile}"
        trap - EXIT

        notify-send -a hyprland -t 2000 "Workspace $workspace" "Layout: $new"
      '';
    })
  ];

  # mkAfter so this is emitted last. Nothing else sets a workspace rule today,
  # so it is defensive rather than load-bearing: it keeps a saved override
  # winning if a static hl.workspace_rule is ever reintroduced upstream of it.
  wayland.windowManager.hyprland.extraConfig = lib.mkAfter ''

    -- Per-workspace layout overrides saved by hypr-workspace-layout-toggle
    -- (SUPER + SHIFT + L), replayed so a toggle survives `hyprctl reload` and
    -- a reboot.
    do
      -- The file is data, not code, but still untrusted input: a hand-edited
      -- layout name would otherwise reach Hyprland and log a config error on
      -- every load.
      local known = { dwindle = true, scrolling = true }

      -- pcall so a truncated file costs the overrides, not the whole config.
      -- Without it hyprland.lua aborts and the session comes up with no binds.
      local ok, err = pcall(function()
        -- nil covers both a missing file and a missing directory, which is the
        -- state on every machine until the bind is first pressed.
        local state = io.open("${stateFile}", "r")
        if not state then return end

        for line in state:lines() do
          local workspace, layout = line:match("^(%d+)=(%a+)$")
          if workspace and known[layout] then
            -- Workspace as a string, matching what the toggle's `hyprctl eval`
            -- sends at runtime, so a live toggle and a later reload produce the
            -- byte-identical rule.
            hl.workspace_rule({ workspace = workspace, layout = layout })
          end
        end

        state:close()
      end)

      if not ok then
        -- Lands in the Hyprland log. There is no notification daemon yet at
        -- config-load time, and failing loudly here would cost the session.
        io.stderr:write("nix-green: workspace-layouts state ignored: " .. tostring(err) .. "\n")
      end
    end
  '';
}
