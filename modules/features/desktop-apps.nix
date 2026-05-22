{ ... }: {
  flake.nixosModules.desktopApps = { pkgs, ... }: {
    programs.firefox.enable = true;

    environment.systemPackages = with pkgs; [
      vim
      wget
      discord-ptb
      steam
      git
      bruno
      wl-clipboard
      tor-browser
    ];

    programs.steam = {
      enable = true;
      extraPackages = [ pkgs.adwaita-icon-theme ];
    };
  };
}
