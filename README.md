# Description
<img width="1920" height="1080" alt="nix-green screenshot" src="https://github.com/user-attachments/assets/51656890-5eca-4a87-9974-e8d9ca5c4ba2" />


This is my nix configuration I use for my systems. The main focus of the configuration is that it is simple to use, lightweight and pre configured with programs that are essential to me. You cand choose between the KDE Plasme desktop environment or Hyprland (tiling manager). This can be installed on most machines due to it's low resource usage.

## In Progress/Future updates
- Hyprland
- Add nix-darwin

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
3. Rebuild your system using **ONE** of the commands below and your good to go! 
```
# For KDE desktop
sudo nixos-rebuild switch --flake .#kde --impure

# For Hyprland desktop
sudo nixos-rebuild switch --flake .#hyprland --impure
``` 
Feel free to customize this configuration to your liking!
