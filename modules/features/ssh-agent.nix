{ ... }: {
  flake.nixosModules.sshAgent = { pkgs, ... }: {
    environment.sessionVariables.SSH_AUTH_SOCK = "$XDG_RUNTIME_DIR/ssh-agent";
    environment.extraInit = ''
      if [ -n "$XDG_RUNTIME_DIR" ] && [ -z "$SSH_AUTH_SOCK" ]; then
        export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent"
      fi

      # Fallback for shells where the user service has not populated the socket yet.
      if [ -n "$SSH_AUTH_SOCK" ] && [ ! -S "$SSH_AUTH_SOCK" ]; then
        ${pkgs.openssh}/bin/ssh-agent -a "$SSH_AUTH_SOCK" >/dev/null
      fi
    '';

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
