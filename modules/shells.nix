{ pkgs, ... }:

{
  home.shellAliases = {
    cat = "bat";
  };

  # Uncomment to enable bash
  #programs.bash.enable = true;

  # Starship hooks itself into each shell through programs.starship's
  # enable*Integration options in starship.nix, so no init line is needed here.
  programs.zsh = {
    enable = true;
    plugins = [
      { name = "zsh-autosuggestions";
        src = "${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions";
      }
      { name = "zsh-syntax-highlighting";
        src = "${pkgs.zsh-syntax-highlighting}/share/zsh-syntax-highlighting";
        file = "zsh-syntax-highlighting.zsh";
      }
    ];
  };

  # Uncomment to enable fish
  #programs.fish.enable = true;
}
