# Description
This is my nix configuration I use for my systems. The main focus of the configuration is that it is simple to use, lightweight and preconfigured with programs that are essential to me. You cand choose between KDE Plasma desktop environment or Hyprland (tiling manager). This can be installed on most machines due to it's low resource usage. 

Feel free to customize this configuration to your liking!

## In Progress/Future updates
- Hyprland
- Add nix-darwin

# Screenshots
## Hyprland
<img width="1911" height="1069" alt="20260223_09h57m09s_grim" src="https://github.com/user-attachments/assets/f9420bea-2ac9-4e58-9f76-5229f889da62" />

## KDE Plasma
<img width="1899" height="952" alt="20260223_21h46m35s_grim" src="https://github.com/user-attachments/assets/b0fe78c3-0a8e-49c7-9838-7af64049d5b4" />

# DISCLAIMER:
**WHILE CHANGES ARE TESTED BEFORE EACH COMMIT, THIS IS AN ONGOING PROJECT THAT CAN POSSIBLY BREAK YOUR SYSTEM. PLEASE INSTALL AT YOUR OWN RISK!**

# How to install
**NOTE: `git` NEEDS TO BE INSTALLED ON YOUR SYSTEM.** 
**THIS CAN BE DONE BY INSTALLING IT IN MANUALLY `/etc/nixos/configuration.nix` OR TEMPORARILY BY RUNNUNG `nix-shell -p git` IN YOUR TERMINAL.**

This setup works right of the box so all you have to do is: 
1. Clone the repo to your directory by opening the terminal, and running the following command:
```
git clone https://github.com/bsgreen44/nix-green
```
2. Update `hostname` and `username` in `~/nix-green/flake.nix` to match your system
3. Rebuild your system using **ONE** of the commands below and you're good to go! 
```
# For KDE desktop
sudo nixos-rebuild switch --flake .#kde --impure

# For Hyprland desktop
sudo nixos-rebuild switch --flake .#hyprland --impure
``` 
