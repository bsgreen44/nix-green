{ pkgs, ... }:

{
  home.packages = with pkgs; [
    (catppuccin-kde.override {
      flavour = [
        "latte"
        "frappe"
        "macchiato"
        "mocha"
      ];
      accents = [
        "blue"
        "lavender"
        "mauve"
        "pink"
      ];
      winDecStyles = [ "modern" ];
    })
  ];

  catppuccin = {
    bat.enable = true;
  };
}
