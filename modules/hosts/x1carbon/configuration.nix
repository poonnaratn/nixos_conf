{ self, ... }: {
  flake.nixosModules.x1CarbonConfiguration = { ... }: {
    imports = [
      self.nixosModules.x1CarbonHardware
      self.nixosModules.x1CarbonIdentity

      self.nixosModules.baseSystem
      self.nixosModules.localeAndTime
      self.nixosModules.plasmaDesktop
      self.nixosModules.audioPipewire
      self.nixosModules.fontsThai
      self.nixosModules.desktopApps
      self.nixosModules.cliTools
      self.nixosModules.powerManagement

      self.nixosModules.keyboard
      self.nixosModules.sshAgent
    ];
  };
}
