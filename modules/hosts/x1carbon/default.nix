{ self, inputs, ... }: {
  flake.nixosConfigurations.x1Carbon = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      self.nixosModules.x1CarbonConfiguration
    ];
  };
}
