{ ... }: {
  flake.nixosModules.cliTools = { lib, pkgs, ... }: {
    environment.systemPackages = with pkgs; [
      fzf
      zoxide
      eza
      docker
    ];

    programs.fzf = {
      keybindings = true;
      fuzzyCompletion = true;
    };

    programs.zoxide = {
      enable = true;
      enableBashIntegration = true;
      enableZshIntegration = true;
    };

    environment.shellAliases = {
      ls = "eza --group-directories-first --icons=auto";
      ll = "eza -la --group-directories-first --icons=auto";
      la = "eza -a --group-directories-first --icons=auto";
      lt = "eza --tree --level=2 --icons=auto";
    };

    virtualisation.docker.enable = true;
    users.users.me.extraGroups = lib.mkAfter [ "docker" ];
  };
}
