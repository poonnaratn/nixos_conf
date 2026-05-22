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

            # Use Copilot key as the nav-layer trigger (commonly exposed as F23).
            # If your hardware reports a different key, run `sudo keyd monitor` and adjust.
            f23 = "layer(nav)";
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
