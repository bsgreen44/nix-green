{ pkgs, lib, config, gazelle, tsui, pvetui, herdr, ... }:

let
  # One global instruction file for every agent harness.
  #
  # Out of the store so it stays editable without a rebuild - agents (and you)
  # append to it. The cost: content is not reproducible from the flake alone.
  # NOT named AGENTS.md, or the harnesses' walk up from cwd would also load it
  # as nix-green's project instructions, twice in this repo.
  # Hardcodes ~/nix-green, as hyprland/home.nix does for the wallpaper.
  agentsContext = config.lib.file.mkOutOfStoreSymlink
    "${config.home.homeDirectory}/nix-green/global-agents.md";

  # VSCodium's settings.json, but writable.
  #
  # Home Manager links it out of the store, so the GUI cannot save anything.
  # Instead, merge `userSettings` below into a real file at activation:
  # Nix-declared keys win on every rebuild, the rest (font, zoom) are yours.
  # Close VSCodium before switching - it rewrites the file from memory.
  vscodiumSettings = "${config.xdg.configHome}/VSCodium/User/settings.json";
  vscodiumDeclared =
    (pkgs.formats.json { }).generate "vscodium-settings-declared"
      config.programs.vscodium.profiles.default.userSettings;
  vscodiumMerge = pkgs.writeShellScript "vscodium-settings-merge" ''
    set -euo pipefail
    PATH=${lib.makeBinPath [ pkgs.jq pkgs.coreutils ]}''${PATH:+:}$PATH

    target="${vscodiumSettings}"
    # Last activation's declared keys, to tell one you dropped from Nix apart
    # from one you set yourself.
    state="${config.xdg.stateHome}/nix-green/vscodium-settings.json"

    mkdir -p "$(dirname "$target")" "$(dirname "$state")"
    # Left over from when Home Manager linked this file.
    if [ -L "$target" ]; then rm -f "$target"; fi
    [ -f "$target" ] || echo "{}" > "$target"
    [ -f "$state" ] || echo "{}" > "$state"

    merged="$(jq -s '
      .[0] as $local | .[1] as $prev | .[2] as $declared
      | (($prev | keys) - ($declared | keys)) as $dropped
      | ($local | delpaths($dropped | map([.]))) * $declared
    ' "$target" "$state" "${vscodiumDeclared}")"

    printf "%s\n" "$merged" > "$target"
    install -m 644 "${vscodiumDeclared}" "$state"
  '';
in

{
  home.packages =
    with pkgs;
    [
      bat
      wget
      git
      fastfetch
      brave
      claude-code
      codex
      obsidian
      nextcloud-client
      libreoffice
      wakeonlan
      bluetui
      calcurse
      cmatrix
      cbonsai
      lazygit
      luarocks
      lua51Packages.lua
      wiremix # audio tui
      signal-desktop
      localsend
      vlc
      yazi #TUI file manager
    ]
    ++ [
      # NetworkManager tui
      gazelle.packages.${pkgs.stdenv.hostPlatform.system}.default

      # herdr (AI coding-agent multiplexer)
      herdr.packages.${pkgs.stdenv.hostPlatform.system}.default

      # pvetui (Proxmox manager tui)
      #pvetui.packages.${pkgs.stdenv.hostPlatform.system}.default

      (pvetui.packages.${pkgs.stdenv.hostPlatform.system}.default.overrideAttrs (oldAttrs: {
        vendorHash = "sha256-7Tuh9T3uTlNxdSlSL7gQIYXpfpNbCkQrRWj/FoU8fbU=";
      }))

      # Tailscale tui
      (pkgs.runCommand "tsui-wrapped" {
        buildInputs = [ pkgs.makeWrapper ];
      } ''
        makeWrapper ${tsui.packages.${pkgs.stdenv.hostPlatform.system}.tsui}/bin/tsui $out/bin/tsui \
          --prefix LD_LIBRARY_PATH : ${pkgs.lib.makeLibraryPath [
            pkgs.libX11
          ]}
      '')
    ];

  # bat config
  programs.bat = {
    enable = true;
    config = {
      pager = "never"; # makes bat act like cat
    };
  };

  # btop config
  programs.btop = {
    enable = true;
    settings = {
      theme_background = false;
    };
  };

  # VSCodium config
  programs.vscodium = {
    enable = true;
    package = pkgs.vscodium;
    profiles.default = {
      extensions = with pkgs.vscode-extensions; [
        anthropic.claude-code
        jnoortheen.nix-ide
      ];
      userSettings = {
        "claudeCode.preferredLocation" = "panel";
        "[markdown]" = {
          "editor.unicodeHighlight.ambiguousCharacters" = false;
          "editor.unicodeHighlight.invisibleCharacters" = false;
          "diffEditor.ignoreTrimWhitespace" = false;
          "editor.wordWrap" = "on";
          "editor.quickSuggestions" = {
            comments = "off";
            strings = "off";
            other = "off";
          };
        };
      };
    };
  };

  # Unlink settings.json; `vscodiumMerge` above writes it instead.
  home.file.${vscodiumSettings}.enable = lib.mkForce false;
  home.activation.vscodiumSettings =
    lib.hm.dag.entryAfter [ "writeBoundary" ] "run ${vscodiumMerge}";

  # Gazelle config
  programs.gazelle = {
    enable = true;
    settings = {
      theme = "nord"; # choose your theme
    };
  };

  programs.clock-rs = {
    enable = true;
    settings = {
      general = {
        color = "green";
        interval = 250;
        blink = false;
        bold = true;
      };
      position = {
        horizontal = "center";
        vertical = "center";
      };
      date = {
        fmt = "%A, %B %d, %Y";
        use_12h = true;
        utc = false;
        hide_seconds = false;
      };
    };
  };

  # Global agent instructions. One file, every harness. See `agentsContext` above
  # for why it is an out-of-store symlink and why it is not called AGENTS.md.
  home.file.".claude/CLAUDE.md".source = agentsContext;      # Claude Code
  home.file.".codex/AGENTS.md".source = agentsContext;       # Codex CLI, $CODEX_HOME
  xdg.configFile."opencode/AGENTS.md".source = agentsContext;

  # opencode
  programs.opencode = {
    enable = true;
    settings = {
      model = "openai/gpt-5.5";
      small_model = "openai/gpt-5.4-mini";
      default_agent = "plan";
      agent = {
        plan.model = "openai/gpt-5.5";
        general.model = "openai/gpt-5.5";
        explore.model = "openai/gpt-5.4-mini";
        scout.model = "openai/gpt-5.4-mini";
      };

      autoupdate = false;

      # Local fallback, selectable at runtime with /models.
      provider = {
        ollama = {
          npm = "@ai-sdk/openai-compatible";
          name = "Ollama";
          options = {
            baseURL = "http://127.0.0.1:11434/v1";
          };
          models = {
            "qwen2.5-coder:3b" = {
              name = "qwen2.5-coder:3b";
            };
          };
        };
      };
    };
  };
  # zen-browser
  programs.zen-browser = {
    enable = true;
    #setAsDefaultBrowser = true;
  };
}
