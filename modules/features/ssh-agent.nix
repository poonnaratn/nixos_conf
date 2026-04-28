{ self, ... }: {
  flake.nixosModules.sshAgent = {
    environment.sessionVariables.SSH_AUTH_SOCK = "$XDG_RUNTIME_DIR/ssh-agent";

    programs.ssh = {
      enableAskPassword = true;
      startAgent = true;
      extraConfig = ''
        Host *
          AddKeysToAgent yes
      '';
    };
  };
}
