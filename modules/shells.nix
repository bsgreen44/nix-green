{ pkgs, ... }:

{
  home.shellAliases = {
  cat = "bat";
  };

  # Uncomment to enable bash
  #programs.bash = {
  #  enable = true;
  #  initExtra = ''
  #    eval "$(starship init bash)"
  #  '';
  #};

  programs.zsh = {
    enable = true;
    plugins = [
      { name = "zsh-autosuggestions";
        src = "${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions";
      }
      { name = "zsh-syntax-highlighting";
        src = "${pkgs.zsh-syntax-highlighting}/share/zsh-syntax-highlighting";
      }
    ];
    initContent = ''
      eval "$(starship init zsh)"
    '';
  };

  # Uncomment to enable fish
  #programs.fish = {
  #  enable = true;
  #  interactiveShellInit = ''
  #    starship init fish | source
  #  '';
  #};
}
