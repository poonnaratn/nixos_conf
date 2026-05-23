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

      modWorkspaceFocusLetters = mkBinds workspaceLetters (k: { "focus-workspace" = k; });
      modWorkspaceMoveLetters = mkBinds workspaceLetters (k: { "move-column-to-workspace" = k; });
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

          input = {
            "mod-key" = "Super";
            "mod-key-nested" = "Super";
            keyboard.xkb = {
              layout = "us,th";
              options = "grp:ctrl_space_toggle";
            };
            touchpad = {
              tap = _: {};
              "natural-scroll" = _: {};
            };
          };

          layout.gaps = 5;
          workspaces = namedLetterWorkspaces;

          binds =
            {
              # Keep common Niri/Cachy-style core actions.
              "Mod+Return".spawn-sh = lib.getExe pkgs.kitty;
              "Mod+Alt+Q".close-window = _: {};
              "Mod+Space".spawn-sh = "${lib.getExe self'.packages.myNoctalia} ipc call launcher toggle";
              "Mod+Left"."focus-column-left" = _: {};
              "Mod+Right"."focus-column-right" = _: {};
              "Mod+Ctrl+Left"."move-column-left" = _: {};
              "Mod+Ctrl+Right"."move-column-right" = _: {};
              "Mod+Tab"."focus-workspace-down" = _: {};
              "Mod+Shift+Tab"."focus-workspace-up" = _: {};
              "Mod+Alt+H"."show-hotkey-overlay" = _: {};

              # Media and brightness keys.
              "XF86AudioRaiseVolume" = _: {
                props.allow-when-locked = true;
                content.spawn-sh = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.1+ -l 1.0";
              };
              "XF86AudioLowerVolume" = _: {
                props.allow-when-locked = true;
                content.spawn-sh = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.1-";
              };
              "XF86AudioMute" = _: {
                props.allow-when-locked = true;
                content.spawn-sh = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
              };
              "XF86AudioMicMute" = _: {
                props.allow-when-locked = true;
                content.spawn-sh = "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle";
              };
              "XF86MonBrightnessUp" = _: {
                props.allow-when-locked = true;
                content.spawn-sh = "brightnessctl --class=backlight set +10%";
              };
              "XF86MonBrightnessDown" = _: {
                props.allow-when-locked = true;
                content.spawn-sh = "brightnessctl --class=backlight set 10%-";
              };
              "XF86AudioPlay" = _: {
                props.allow-when-locked = true;
                content.spawn-sh = "playerctl play-pause";
              };
              "XF86AudioPause" = _: {
                props.allow-when-locked = true;
                content.spawn-sh = "playerctl play-pause";
              };
              "XF86AudioStop" = _: {
                props.allow-when-locked = true;
                content.spawn-sh = "playerctl stop";
              };
              "XF86AudioPrev" = _: {
                props.allow-when-locked = true;
                content.spawn-sh = "playerctl previous";
              };
              "XF86AudioNext" = _: {
                props.allow-when-locked = true;
                content.spawn-sh = "playerctl next";
              };
            }
            # Numbered and lettered workspace access on Mod/Super.
            // (lib.mapAttrs' (k: v: lib.nameValuePair "Mod+${k}" v) modWorkspaceFocus)
            // (lib.mapAttrs' (k: v: lib.nameValuePair "Mod+Shift+${k}" v) modWorkspaceMove)
            // (lib.mapAttrs' (k: v: lib.nameValuePair "Mod+${lib.toUpper k}" v) modWorkspaceFocusLetters)
            // (lib.mapAttrs' (k: v: lib.nameValuePair "Mod+Shift+${lib.toUpper k}" v) modWorkspaceMoveLetters);
        };
      };
    };
}
