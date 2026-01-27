# Description
This is my nix configuration I use for my systems. The main focus of the configuration is that it is simple to use, lightweight and pre configured with programs that are essential to me. It utilizes the KDE desktop environment which is similar to the Windows desktop. This can be installed on most laptops and desktops due to it's low resource usage. It can also be run as a VM. 

This setup works right of the box so all you have to do is: 
1. Clone the repo to your directory by opening the terminal, and running the following command
```
git clone https://github.com/bsgreen44/nix-green
```
2. Update `hostname` and `username` in `~/nix-green/flake.nix` to match your system
3. Rebuild your system using the command below and your good to go! 
```
sudo nixos-rebuild switch --flake --impure
``` 
Feel free to customize this configuration to your liking!
