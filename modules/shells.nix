{ ... }:

{
  programs.bash = {
    enable = true;
    initExtra = ''
      eval "$(starship init bash)"
    '';
  };

  # Uncomment to enable zsh
  # programs.zsh = {
  #   enable = true;
  #   initExtra = ''
  #     eval "$(starship init zsh)"
  #   '';
  # };

  # Uncomment to enable fish
  # programs.fish = {
  #   enable = true;
  #   interactiveShellInit = ''
  #     starship init fish | source
  #   '';
  # };
}
