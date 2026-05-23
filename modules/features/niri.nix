{ self, inputs, ... }: {
  flake.nixosModules.niri = { pkgs, lib, ... }: {
    environment.systemPackages = [ pkgs.kitty ];
    programs.niri = {
      enable = true;
      package = self.packages.${pkgs.stdenv.hostPlatform.system}.myNiri;
    };
  };

  perSystem = { pkgs, lib, self', ... }:
    let
      # Full letter workspace mapping a-z.
      workspaceLetters = [
        "a" "b" "c" "d" "e" "f" "g" "h" "i" "j" "k" "l" "m"
        "n" "o" "p" "q" "r" "s" "t" "u" "v" "w" "x" "y" "z"
      ];

      numberKeys = [
        "1" "2" "3" "4" "5" "6" "7" "8" "9"
      ];

      mkBinds = keys: mkAction: builtins.listToAttrs (map (k: {
        name = k;
        value = mkAction k;
      }) keys);

      modWorkspaceFocus = mkBinds numberKeys (k: { "focus-workspace" = builtins.fromJSON k; });
      modWorkspaceMove = mkBinds numberKeys (k: { "move-column-to-workspace" = builtins.fromJSON k; });

      altWorkspaceFocusNumbers = mkBinds numberKeys (k: { "focus-workspace" = builtins.fromJSON k; });
      altWorkspaceMoveNumbers = mkBinds numberKeys (k: { "move-column-to-workspace" = builtins.fromJSON k; });

      altWorkspaceFocusLetters = mkBinds workspaceLetters (k: { "focus-workspace" = k; });
      altWorkspaceMoveLetters = mkBinds workspaceLetters (k: { "move-column-to-workspace" = k; });
      namedLetterWorkspaces = mkBinds workspaceLetters (_: _: {});
    in
    {
      packages.myNiri = inputs.wrapper-modules.wrappers.niri.wrap {
        inherit pkgs; # THIS PART IS VERY IMPORTAINT, I FORGOT IT IN THE VIDEO!!!
        settings = {
          spawn-at-startup = [
            (lib.getExe self'.packages.myNoctalia)
          ];

          xwayland-satellite.path = lib.getExe pkgs.xwayland-satellite;

          input.keyboard.xkb.layout = "us,ua";

          layout.gaps = 5;
          workspaces = namedLetterWorkspaces;

          binds =
            {
              # Keep common Niri/Cachy-style core actions.
              "Mod+Return".spawn-sh = lib.getExe pkgs.kitty;
              "Mod+Q".close-window = _: {};
              "Mod+S".spawn-sh = "${lib.getExe self'.packages.myNoctalia} ipc call launcher toggle";
              "Mod+H"."focus-column-left" = _: {};
              "Mod+L"."focus-column-right" = _: {};
              "Mod+Ctrl+H"."move-column-left" = _: {};
              "Mod+Ctrl+L"."move-column-right" = _: {};
              "Mod+Tab"."focus-workspace-down" = _: {};
              "Mod+Shift+Tab"."focus-workspace-up" = _: {};
            }
            # Keep numbered workspace access on both Mod and Alt.
            // (lib.mapAttrs' (k: v: lib.nameValuePair "Mod+${k}" v) modWorkspaceFocus)
            // (lib.mapAttrs' (k: v: lib.nameValuePair "Mod+Shift+${k}" v) modWorkspaceMove)
            // (lib.mapAttrs' (k: v: lib.nameValuePair "Alt+${k}" v) altWorkspaceFocusNumbers)
            // (lib.mapAttrs' (k: v: lib.nameValuePair "Alt+Shift+${k}" v) altWorkspaceMoveNumbers)
            # Full letter workspace mapping a-z.
            // (lib.mapAttrs' (k: v: lib.nameValuePair "Alt+${lib.toUpper k}" v) altWorkspaceFocusLetters)
            // (lib.mapAttrs' (k: v: lib.nameValuePair "Alt+Shift+${lib.toUpper k}" v) altWorkspaceMoveLetters);
        };
      };
    };
}
