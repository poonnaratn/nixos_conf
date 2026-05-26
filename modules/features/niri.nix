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
              # Core launchers.
              "Mod+Return".spawn-sh = lib.getExe pkgs.kitty;
              "Mod+Space".spawn-sh = "${lib.getExe self'.packages.myNoctalia} ipc call launcher toggle";

              # Core window actions.
              "Mod+Ctrl+Q"."close-window" = _: {};
              "Mod+Ctrl+M"."maximize-window-to-edges" = _: {};
              "Mod+Ctrl+F"."fullscreen-window" = _: {};
              "Mod+Ctrl+T"."toggle-window-floating" = _: {};
              "Mod+Ctrl+W"."toggle-column-tabbed-display" = _: {};
              "Mod+Ctrl+O" = _: {
                props.repeat = false;
                content."toggle-overview" = _: {};
              };
              "Mod+Ctrl+Shift+Escape"."show-hotkey-overlay" = _: {};
              "Mod+Ctrl+Escape" = _: {
                props."allow-inhibiting" = false;
                content."toggle-keyboard-shortcuts-inhibit" = _: {};
              };
              "Mod+Ctrl+Shift+P"."power-off-monitors" = _: {};
              "Ctrl+Alt+Delete".quit = _: {};

              # Focus movement.
              "Mod+Ctrl+H"."focus-column-left" = _: {};
              "Mod+Ctrl+L"."focus-column-right" = _: {};
              "Mod+Ctrl+K"."focus-window-up" = _: {};
              "Mod+Ctrl+J"."focus-window-down" = _: {};
              "Mod+Ctrl+Home"."focus-column-first" = _: {};
              "Mod+Ctrl+End"."focus-column-last" = _: {};
              "Mod+Ctrl+Tab"."focus-workspace-previous" = _: {};

              # Move windows and columns.
              "Mod+Ctrl+Shift+H"."move-column-left" = _: {};
              "Mod+Ctrl+Shift+L"."move-column-right" = _: {};
              "Mod+Ctrl+Shift+K"."move-window-up" = _: {};
              "Mod+Ctrl+Shift+J"."move-window-down" = _: {};
              "Mod+Ctrl+Shift+Home"."move-column-to-first" = _: {};
              "Mod+Ctrl+Shift+End"."move-column-to-last" = _: {};

              # Monitor focus and send.
              "Mod+Ctrl+Left"."focus-monitor-left" = _: {};
              "Mod+Ctrl+Right"."focus-monitor-right" = _: {};
              "Mod+Ctrl+Up"."focus-monitor-up" = _: {};
              "Mod+Ctrl+Down"."focus-monitor-down" = _: {};
              "Mod+Ctrl+Shift+Left"."move-column-to-monitor-left" = _: {};
              "Mod+Ctrl+Shift+Right"."move-column-to-monitor-right" = _: {};
              "Mod+Ctrl+Shift+Up"."move-column-to-monitor-up" = _: {};
              "Mod+Ctrl+Shift+Down"."move-column-to-monitor-down" = _: {};

              # Layout controls.
              "Mod+Ctrl+Shift+F"."expand-column-to-available-width" = _: {};
              "Mod+Ctrl+C"."center-column" = _: {};
              "Mod+Ctrl+Shift+C"."center-visible-columns" = _: {};
              "Mod+Ctrl+Minus"."set-column-width" = "-10%";
              "Mod+Ctrl+Equal"."set-column-width" = "+10%";
              "Mod+Ctrl+Shift+Minus"."set-window-height" = "-10%";
              "Mod+Ctrl+Shift+Equal"."set-window-height" = "+10%";

              # Screenshot actions.
              "Ctrl+Shift+1".screenshot = _: {};
              "Ctrl+Shift+2"."screenshot-screen" = _: {};
              "Ctrl+Shift+3"."screenshot-window" = _: {};

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
            # Workspace access on Mod/Super: by index and by named letter.
            // (lib.mapAttrs' (k: v: lib.nameValuePair "Mod+${k}" v) modWorkspaceFocus)
            // (lib.mapAttrs' (k: v: lib.nameValuePair "Mod+Shift+${k}" v) modWorkspaceMove)
            // (lib.mapAttrs' (k: v: lib.nameValuePair "Mod+${lib.toUpper k}" v) modWorkspaceFocusLetters)
            // (lib.mapAttrs' (k: v: lib.nameValuePair "Mod+Shift+${lib.toUpper k}" v) modWorkspaceMoveLetters);
        };
      };
    };
}
