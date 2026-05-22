{ ... }: {
  flake.nixosModules.x1CarbonIdentity = { pkgs, ... }: {
    networking.hostName = "nixos";

    users.users.me = {
      isNormalUser = true;
      description = "me";
      extraGroups = [ "networkmanager" "wheel" ];
      packages = with pkgs; [
      ];
    };
  };
}
