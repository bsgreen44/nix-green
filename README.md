# Description
This is my nix configuration I use for my systems. The main focus of the configuration is that it is simple to use, lightweight and preconfigured with programs that are essential to me. You can choose between [KDE Plasma](https://kde.org/plasma-desktop/) or [Hyprland](https://hypr.land/). This can be installed on most machines due to it's low resource usage. Feel free to use this configuration as is or customize it to how you see fit!

## In Progress/Future updates
- Add nix-darwin support

# Folder Structure
```
nix-green
├── configuration.nix
├── dotfiles
├── flake.lock
├── flake.nix
├── global-agents.md
├── hyprland
│   ├── configuration.nix
│   └── home.nix
├── kde
│   ├── configuration.nix
│   └── home.nix
├── linux
│   ├── home.nix
│   └── hyprland.nix
├── modules
│   ├── hypr-workspace-layout.nix
│   ├── hypridle.nix
│   ├── hyprland.nix
│   ├── hyprlock.nix
│   ├── kdethemes.nix
│   ├── mako.nix
│   ├── neovim.nix
│   ├── packages.nix
│   ├── palette.nix
│   ├── rofi.nix
│   ├── screensaver.nix
│   ├── shells.nix
│   ├── starship.nix
│   ├── swayosd.nix
│   ├── terminal.nix
│   ├── themes.nix
│   └── waybar.nix
├── README.md
├── scripts
│   └── detect-system-apps.sh
└── wallpapers
```

# Screenshots
<img width="1907" height="1057" alt="20260806_12h02m12s_grim" src="https://github.com/user-attachments/assets/add3248f-c40f-4357-92cc-ebc1b4818b88" />

<img width="1903" height="1072" alt="20260806_12h15m35s_grim" src="https://github.com/user-attachments/assets/32c1df3d-f85a-4bae-b175-6b38e2938a73" />


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
3. While in the `nix-green` directory, rebuild your system using **ONE** of the commands below and you're good to go! 
```
# Make sure you're in the correct directory
cd ~/nix-green

# For KDE desktop
sudo nixos-rebuild switch --flake .#kde --impure

# For Hyprland desktop
sudo nixos-rebuild switch --flake .#hyprland --impure
``` 

# FAQ

### Can I use this on a different Linux distro?
Yes (mostly)! The `~/nix-green/modules` directory contains all of the Home Manager setup including packages, dotfiles and user preferences. What won't transfer over are system level settings and services specific to NixOS set in `configuration.nix` such as boot loader, kernel, openssh and tailscale. These are set on your linux distro.

To install on any Linux distro:
1. Install Nix Determinate 
```
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```
2. Clone the repo and run home-manager switch command
```
git clone https://github.com/bsgreen44/nix-green 
cd ~/nix-green
nix run home-manager/master -- switch --flake .#username
```

Any future updates use:
```
home-manager switch --flake .#username
```

### Can I run the Hyprland desktop on a different Linux distro?
Yes. There are two Home Manager configurations: `.#username` installs CLI tools and dotfiles only, and `.#username-hyprland` adds the Hyprland desktop on top of it. Nix writes the config, your distro supplies the compositor.

1. Install `hyprland`, `xdg-desktop-portal-hyprland` and `hyprlock` with your distro's package manager. Some distros ship these in a third-party repository rather than the default ones.
2. Switch to the desktop configuration
```
home-manager switch --flake .#username-hyprland
```
3. On a laptop, allow swayosd to control screen brightness (see the FAQ entry below). Volume works without this.
4. Log out and pick Hyprland from your login screen's session list.

Distro-specific settings, such as the wallpaper path, live in `~/nix-green/linux/hyprland.nix`.

### How do I use apps my distro already installed, instead of the ones Nix declares?
`modules/apps.nix` defines a role registry - `terminal`, `fileManager`, `calculator`, `imageViewer`, `archiver`, `pdfViewer`. Each role names the command to run, its Wayland `app_id` (for the floating window rules), its `.desktop` file (for default-application handling) and the package Nix installs for it. Setting a role's `package = null` means "the distro provides this binary, install nothing".

The defaults are the nixpkgs apps, and every override for your machine goes in one file, `linux/system-apps.nix`. To find out what your distro already has:
```
./scripts/detect-system-apps.sh
```
It scans `/usr/bin` (never `$PATH`, which would match Nix's own packages), reports the owning distro package, and prints a `green.apps` block to paste into `linux/system-apps.nix`. Moving to another distro means rewriting that one file, or emptying it to `green.apps = { };` to have Nix install everything again.

The scan is a script rather than something the config does during evaluation, because a flake evaluates in pure mode: `builtins.pathExists "/usr/bin/dolphin"` returns `false` there even when the file exists, and with `eval-cache` on, an `--impure` answer can go stale. Declaring the result keeps the config reproducible.

Two things the registry does not cover. The `terminal` and `browser` locals at the top of `modules/hyprland.nix` are deliberately literal, so retargeting `terminal.command` changes waybar, rofi and the screensaver but not `SUPER + Return` - edit that local by hand. And `app_id` values the script reads from a `.desktop` name are a guess; confirm them with `hyprctl clients -j | jq -r '.[].class'` with the app open, or its window will not float.

### Why don't my brightness keys work on a different Linux distro?
Nix installs swayosd and runs it as a user service, but it can't set the permissions swayosd needs to change brightness. That part is a system-level change, so it has to be done once, by hand, as root. On NixOS `hyprland/configuration.nix` already handles it.

The kernel exposes brightness at `/sys/class/backlight/*/brightness`, owned by `root` and read-only for everyone else. swayosd runs as your user and writes that file directly, so it needs write access. Backlight devices have no `/dev` node, which is why udev's usual `GROUP=`/`MODE=` settings don't apply here and the rule has to call `chgrp`/`chmod` itself.

1. Give the `video` group write access to brightness
```
sudo tee /etc/udev/rules.d/99-swayosd.rules > /dev/null <<'EOF'
ACTION=="add", SUBSYSTEM=="backlight", RUN+="/usr/bin/chgrp video /sys/class/backlight/%k/brightness"
ACTION=="add", SUBSYSTEM=="backlight", RUN+="/usr/bin/chmod g+w /sys/class/backlight/%k/brightness"
EOF
```
2. Add yourself to the `video` group
```
sudo usermod -aG video $USER
```
3. Apply the rule without rebooting
```
sudo udevadm control --reload
sudo udevadm trigger --action=add --subsystem-match=backlight
```
4. Log out and back in, so your graphical session (and the swayosd service in it) picks up the new group.

Check it worked. The file should be group `video` and group-writable (`rw-rw-r--`), and `video` should appear in your groups:
```
ls -l /sys/class/backlight/*/brightness
id -nG
```

Installing swayosd from your distro's package manager instead is not a substitute: it would still not add you to the `video` group, it duplicates the copy Nix already installs, and not every distro packages it (Fedora does not).

### How do I update the system and packages?
In `~/nix-green` directory, run `sudo nix flake update`. This will update `flake.lock`. Then `sudo nixos-rebuild --flake .#changethis --impure` replacing `changethis` with `kde` or `hyprland`.

On other distros, run `nix flake update` followed by `home-manager switch --flake .#username`, or `.#username-hyprland` if you installed the desktop.

### Where do I put instructions for AI coding agents?

`global-agents.md` in the repo root. It is the single source of truth, and `modules/packages.nix` links it into every harness's global instruction path:

| Harness | Path |
| --- | --- |
| Claude Code | `~/.claude/CLAUDE.md` |
| Codex CLI | `~/.codex/AGENTS.md` |
| opencode | `~/.config/opencode/AGENTS.md` |

All three are `mkOutOfStoreSymlink` links, which point at the working tree rather than the Nix store. Edit `global-agents.md` and every agent picks the change up on its next run - no `home-manager switch`, no `nixos-rebuild`. The cost is that the content is not reproducible from the flake alone; it is whatever the checkout holds. That is deliberate, because a read-only store symlink would stop the agents (and you) from appending to their own instructions.

The path is hardcoded to `~/nix-green`. A checkout anywhere else needs `agentsContext` in `modules/packages.nix` edited.

**Why it is not called `AGENTS.md`.** All three harnesses walk up from the current directory looking for a project `AGENTS.md`. Naming the file that would make it double as *this repo's* project instructions, so working inside `nix-green` would load the same content twice - once globally, once as project context. opencode keys its instruction set on `path.resolve`, which does not follow symlinks, so it cannot tell the two apart; neither it nor Codex has a way to opt out. The `global-agents.md` name is discovered by nothing, so it stays purely global. Project instructions, if this repo ever wants them, belong in a separate `AGENTS.md` or `CLAUDE.md`.
## Hyprland

### Is there a keybind list?
`SUPER + SHIFT + H` opens a searchable keybind list. Edit the keybinds in `hyprland.nix`, and the descriptions in `rofi.nix`. App names that come from the role registry (terminal, file manager) are interpolated into both, so those stay in sync on their own. See [hyprland wiki](https://wiki.hypr.land/Configuring/Binds/) on how to set binds.

### How do I change the wallpaper?
Set `wallpaper` in the `_module.args` block to the path of the desired wallpaper. On NixOS this is in `~/nix-green/hyprland/home.nix`; on other distros it's `~/nix-green/linux/hyprland.nix`.
```
  _module.args = {
    wallpaper = "/home/${username}/nix-green/wallpapers/linux-catppuccin.jpg";
  };
```
Rebuilding is enough when the path changes: swaybg runs as the `swaybg` user service, and `home-manager switch` restarts it. Only editing an image in place under the same filename needs a manual restart:
```
systemctl --user restart swaybg
```
If your wallpaper is not in `~/nix-green/wallpapers/` make sure to update this to the desired path. The wallpaper doubles as the hyprlock background. `-m fill` crops to cover, so size the image for your widest monitor.

### How do I change the hyprland environment?
hyprland    ----> `hyprland.nix` `hyprlock.nix` `hypridle.nix`

waybar      ----> `waybar.nix`

rofi (menu) ----> `rofi.nix`

After changes are made run `sudo nixos-rebuild --flake .#hyprland --impure`, or `home-manager switch --flake .#username-hyprland` on other distros.
*NOTE: hyprland is managed by home manager. DO NOT modify files in `~/.config`. Any changes to the files will be overwritten after rebuild.*

### Is there a way to manage hyprland NOT through nix?
For quick, machine-local tweaks that you don't want tracked in the flake, uncomment the `source` line in the monitor section of `hyprland.nix` and create the file:
```
# source = ~/.config/hypr/local.conf
```
Hyprland sources that file (monitor layout, keybinds, etc.) if it exists, and treats a missing file as a harmless no-op. Edit it and run `hyprctl reload` to apply without a rebuild. Note this is mutable, untracked state that lives outside the flake, so it is not reproducible across machines.

### How do I change the scaling and resolution?

There are 2 options:

#### Use `hyprmon`
Easiest and quickest. Not persistent across reboots and rebuilds.

#### hidpi toggle
For hi-DPI (2k/4k) laptop panels there's a declarative `hidpi` flag instead of editing the monitor lines by hand. It's set per machine in the `_module.args` block, alongside the wallpaper path - `~/nix-green/hyprland/home.nix` on NixOS, `~/nix-green/linux/hyprland.nix` on other distros:
```
_module.args = {
  hidpi = false;   # set true on 2k/4k laptop panels
};
```
When `hidpi = true`, `hyprland.nix` emits the scaled monitor block (`monitor = eDP-1, preferred, auto, 1.5` and `env = GDK_SCALE, 1.5`) via the `monitorConfig` binding; when `false` it uses the default `monitor = , preferred, auto, 1`. Flip the flag and run `sudo nixos-rebuild --flake .#hyprland --impure`, or `home-manager switch --flake .#username-hyprland` on other distros.

Alternatively, you can manually update `monitorConfig` block in `hyprland.nix` to your exact preferences or add the monitor config to `~/.config/hypr/local.conf` to override the monitor settings. Just make sure to uncomment `# source = ~/.config/hypr/local.conf` in hyprland.nix.

### How do I change the screensaver?
Edit `screensaver.nix` to change the screensaver text/ASCII art.

To turn the screensaver off, flip the `green.screensaver.enable` option - `~/nix-green/hyprland/home.nix` on NixOS, `~/nix-green/linux/hyprland.nix` on other distros:
```
green.screensaver.enable = false;
```
When `true`, hypridle's 3-minute idle timeout runs `screensaver --lock`, and the screensaver locks the session itself after a further 2 minutes. When `false`, that timeout runs `loginctl lock-session` directly. The 2.5-minute dim, 5.5-minute display-off and 20-minute suspend listeners are the same either way, and `SUPER + SHIFT + Z` still launches the screensaver by hand in both cases.

Flip the flag and run `sudo nixos-rebuild --flake .#hyprland --impure`, or `home-manager switch --flake .#username-hyprland` on other distros.

### How do I toggle a workspace's layout?
`SUPER + SHIFT + L` flips the active workspace between `dwindle` and `scrolling`. It's per-workspace - other workspaces keep whatever they were last set to - and persists across `hyprctl reload` and reboot, unlike the general `layout` setting in `hyprland.nix`, which only picks the default a workspace starts from.

The toggle writes the override to `~/.local/state/nix-green/workspace-layouts`, and `hypr-workspace-layout.nix` replays it into a `hl.workspace_rule(...)` call on every config load. Note this is mutable, untracked state that lives outside the flake, so it is not reproducible across machines. Deleting that file and running `hyprctl reload` resets every workspace back to the layout declared in Nix.
