# Description
This is my nix configuration I use for my systems. The main focus of the configuration is that it is simple to use, lightweight and preconfigured with programs that are essential to me. You can choose between [KDE Plasma](https://kde.org/plasma-desktop/) or [Hyprland](https://hypr.land/). This can be installed on most machines due to it's low resource usage. Feel free to use this configuration as is or customize it to how you see fit!

## In Progress/Future updates
- Add nix-darwin support

# Folder Structure
```
nix-green
├── configuration.nix
├── flake.lock
├── flake.nix
├── hyprland
│   ├── configuration.nix
│   └── home.nix
├── kde
│   ├── configuration.nix
│   └── home.nix
├── modules
│   ├── hypridle.nix
│   ├── hyprland.nix
│   ├── hyprlock.nix
│   ├── kdethemes.nix
|   ├── mako.nix
│   ├── neovim.nix
│   ├── packages.nix
│   ├── rofi.nix
│   ├── screensaver.nix
│   ├── shells.nix
│   ├── starship.nix
│   ├── terminal.nix
│   ├── themes.nix
│   └── waybar.nix
├── README.md
└── wallpapers
    ├── linux-catppuccin.jpg
    ├── nix-wallpaper-nineish-catppuccin-frappe-alt.png
    ├── nix-wallpaper-nineish-catppuccin-latte.png
    ├── nix-wallpaper-nineish-catppuccin-macchiato.png
    └── nix-wallpaper-nineish-catppuccin-mocha-alt.png
```

# Screenshots
## Hyprland
<img width="1911" height="1069" alt="20260223_09h57m09s_grim" src="https://github.com/user-attachments/assets/f9420bea-2ac9-4e58-9f76-5229f889da62" />

## KDE Plasma
<img width="1899" height="952" alt="20260223_21h46m35s_grim" src="https://github.com/user-attachments/assets/b0fe78c3-0a8e-49c7-9838-7af64049d5b4" />

# DISCLAIMER:
**WHILE CHANGES ARE TESTED BEFORE EACH COMMIT, THIS IS AN ONGOING PROJECT THAT CAN POSSIBLY BREAK YOUR SYSTEM. PLEASE INSTALL AT YOUR OWN RISK!**

# How to install
**NOTE: `git` NEEDS TO BE INSTALLED ON YOUR SYSTEM.** 
**THIS CAN BE DONE BY INSTALLING IT IN MANUALLY `/etc/nixos/configuration.nix` OR TEMPORARILY IN AN INTERACPTIVE SHELL BY RUNNUNG `nix-shell -p git` IN YOUR TERMINAL.**

This setup works right of the box so all you have to do is: 
1. Clone the repo to your directory by opening the terminal, and running the following command (*if you are using `nix-shell` make sure it to `exit` the shell after running the command*):
```
git clone https://github.com/bsgreen44/nix-green
```
2. Update `hostname` and `username` in `~/nix-green/flake.nix` to match your system
```
    let
      hostname = "nixos"; # change to your hostname
      username = "green"; # change to your username
    in
```
3. Rebuild your system using **ONE** of the commands below and you're good to go! 
```
# For KDE desktop
sudo nixos-rebuild switch --flake .#kde --impure

# For Hyprland desktop
sudo nixos-rebuild switch --flake .#hyprland --impure
``` 

# FAQ

### How do I update the system and packages?
In `~/nix-green` directory, run `sudo nix flake update`. This will update `flake.lock`. Then `sudo nixos-rebuild --flake .#changethis --impure` replacing `changethis` with `kde` or `hyprland`.

## Hyprland

### Is there a keybind list?
`SUPER + SHIFT + H` opens a searchable keybind list. Edit the keybinds in `hyprland.nix`. After changing the keybind, update the keybinds list in `rofi.nix`. See [hyprland wiki](https://wiki.hypr.land/Configuring/Binds/) on how to set binds.

### How do I change the wallpaper?
In `~/nix-green/hyprland/home.nix` line 4, set it to the path of the desired wallpaper
```
  { pkgs, username, ... }:
{
  _module.args = {
    wallpaper = "/home/${username}/nix-green/wallpapers/linux-catppuccin.jpg";
  };
```

### How do I change the hyprland environment?
hyprland    ----> `hyprland.nix` `hyprlock.nix` `hypridle.nix`

waybar      ----> `waybar.nix`

rofi (menu) ----> `rofi.nix`

After changes are made run `sudo nixos-rebuild --flake .#hyprland --impure`. 
*NOTE: hyprland is managed by home manager. DO NOT modify files in `~/.config`. Any changes to the files will be overwritten after rebuild.*

### How do I change the scaling and resolution?
Use `hyprmon` to make any immediate changes. To make permanent changes that are persistent after reboots and rebuilds, update the monitor configuration section in `hyprland.nix`
```
# Monitor configuration
monitor = , preferred, auto, 1
monitor = eDP-2, 2560x1600@60.00Hz, auto, 1.25 # used for 2k/4k laptop
```

### How do I change the screensaver?
Edit `screensaver.nix` change the screensaver text/ASCII art. To turn off the screensaver, comment out the screensaver lines in `hypridle.nix` and comment in the lock screen.
```
{
  # 3 minutes turn on screensaver.
  # After 5 minutes lock the screen and turn display off. After 20 minutes suspend
  timeout = 180;
  on-timeout = ''sh -c "pgrep -x hyprlock > /dev/null......;
{
#{
#  timeout = 180; # 3 minutes
#  on-timeout = "loginctl lock-session"; # Lock screen
#}
```