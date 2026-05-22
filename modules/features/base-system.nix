{ ... }: {
  flake.nixosModules.baseSystem = { pkgs, ... }: {
    nix.settings.experimental-features = [ "nix-command" "flakes" ];

    hardware.graphics.enable = true;
    hardware.graphics.enable32Bit = true;
    hardware.bluetooth.enable = true;

    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;
    boot.kernelPackages = pkgs.linuxPackages_latest;

    networking.networkmanager.enable = true;

    nixpkgs.config.allowUnfree = true;
    system.stateVersion = "25.11";
  };
}
