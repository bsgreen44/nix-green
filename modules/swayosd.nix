{ pkgs, palette, ... }:

let
  ## On-screen display for volume and brightness.
  style = pkgs.writeText "swayosd-style.css" ''
    window#osd {
        /* GTK's CSS parser rejects #rrggbbaa, so alpha() does the mixing.
           0.8 matches mako's `cc` suffix on the same base colour. */
        background: alpha(#${palette.base}, 0.8);
        border: 2px solid #${palette.mauve};
        border-radius: 999px;
    }

    window#osd #container {
        margin: 16px;
    }

    window#osd image,
    window#osd label {
        color: #${palette.text};
    }

    window#osd progressbar:disabled,
    window#osd image:disabled {
        opacity: 0.5;
    }

    window#osd progressbar {
        min-height: 6px;
        border-radius: 999px;
        background: transparent;
        border: none;
    }

    window#osd trough {
        min-height: inherit;
        border-radius: inherit;
        border: none;
        background: #${palette.surface0};
    }

    window#osd progress {
        min-height: inherit;
        border-radius: inherit;
        border: none;
        background: #${palette.mauve};
    }
  '';
in
{
  services.swayosd = {
    enable = true;
    stylePath = style;
  };
}
