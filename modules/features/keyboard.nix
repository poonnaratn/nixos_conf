{ self, ... }: {
  flake.nixosModules.keyboard = {
    services.keyd = {
      enable = true;

      keyboards.default = {
        ids = [ "*" ];

        settings = {
          main = {
            # Tap CapsLock for Escape, hold for Control.
            capslock = "overload(control, esc)";

            # Hold Right Alt to enter the "nav" layer.
            rightalt = "layer(nav)";
          };

          nav = {
            h = "left";
            j = "down";
            k = "up";
            l = "right";
            u = "pageup";
            d = "pagedown";
            n = "home";
            m = "end";
          };
        };
      };
    };
  };
}
