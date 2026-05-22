{ ... }: {
  flake.nixosModules.fontsThai = { pkgs, ... }: {
    fonts = {
      packages = with pkgs; [
        noto-fonts
        noto-fonts-cjk-sans
        noto-fonts-color-emoji
        tlwg
      ];

      fontconfig.defaultFonts = {
        sansSerif = [ "Noto Sans Thai" "Noto Sans" ];
        serif = [ "Noto Serif Thai" "Noto Serif" ];
        monospace = [ "Noto Sans Mono" ];
      };
    };
  };
}
