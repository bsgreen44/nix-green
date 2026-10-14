# NixOS module (not Home Manager): proprietary NVIDIA driver, on when
# install.sh detected an NVIDIA GPU (`gpu = "nvidia";` in flake.nix). AMD and
# Intel need nothing beyond the Mesa drivers NixOS ships by default.
#
# Assumes the NVIDIA card drives the displays (a desktop). A hybrid laptop
# also needs hardware.nvidia.prime with its bus IDs for render offload.
{ config, lib, gpu, ... }:

lib.mkIf (gpu == "nvidia") {
  hardware.graphics.enable = true;
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    modesetting.enable = true; # required by Wayland compositors
    open = true; # open kernel module, Turing (RTX 20xx / GTX 16xx) and newer
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  # VA-API video decode and GLX through the NVIDIA driver under Hyprland.
  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "nvidia";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
  };
}
