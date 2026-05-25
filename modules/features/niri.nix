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
              "Mod+Alt+Q"."close-window" = _: {};
              "Mod+Alt+M"."maximize-window-to-edges" = _: {};
              "Mod+Alt+F"."fullscreen-window" = _: {};
              "Mod+Alt+T"."toggle-window-floating" = _: {};
              "Mod+Alt+W"."toggle-column-tabbed-display" = _: {};
              "Mod+Alt+O" = _: {
                props.repeat = false;
                content."toggle-overview" = _: {};
              };
              "Mod+Alt+Shift+Escape"."show-hotkey-overlay" = _: {};
              "Mod+Alt+Escape" = _: {
                props."allow-inhibiting" = false;
                content."toggle-keyboard-shortcuts-inhibit" = _: {};
              };
              "Mod+Alt+Shift+P"."power-off-monitors" = _: {};
              "Ctrl+Alt+Delete".quit = _: {};

              # Focus movement.
              "Mod+Alt+Left"."focus-column-left" = _: {};
              "Mod+Alt+H"."focus-column-left" = _: {};
              "Mod+Alt+Right"."focus-column-right" = _: {};
              "Mod+Alt+L"."focus-column-right" = _: {};
              "Mod+Alt+Up"."focus-window-up" = _: {};
              "Mod+Alt+K"."focus-window-up" = _: {};
              "Mod+Alt+Down"."focus-window-down" = _: {};
              "Mod+Alt+J"."focus-window-down" = _: {};
              "Mod+Alt+Home"."focus-column-first" = _: {};
              "Mod+Alt+End"."focus-column-last" = _: {};
              "Mod+Alt+Tab"."focus-workspace-previous" = _: {};

              # Move windows and columns.
              "Mod+Alt+Ctrl+Left"."move-column-left" = _: {};
              "Mod+Alt+Ctrl+H"."move-column-left" = _: {};
              "Mod+Alt+Ctrl+Right"."move-column-right" = _: {};
              "Mod+Alt+Ctrl+L"."move-column-right" = _: {};
              "Mod+Alt+Ctrl+Up"."move-window-up" = _: {};
              "Mod+Alt+Ctrl+K"."move-window-up" = _: {};
              "Mod+Alt+Ctrl+Down"."move-window-down" = _: {};
              "Mod+Alt+Ctrl+J"."move-window-down" = _: {};
              "Mod+Alt+Ctrl+Home"."move-column-to-first" = _: {};
              "Mod+Alt+Ctrl+End"."move-column-to-last" = _: {};

              # Monitor focus and send.
              "Mod+Alt+Shift+Left"."focus-monitor-left" = _: {};
              "Mod+Alt+Shift+Right"."focus-monitor-right" = _: {};
              "Mod+Alt+Shift+Up"."focus-monitor-up" = _: {};
              "Mod+Alt+Shift+Down"."focus-monitor-down" = _: {};
              "Mod+Alt+Shift+Ctrl+Left"."move-column-to-monitor-left" = _: {};
              "Mod+Alt+Shift+Ctrl+Right"."move-column-to-monitor-right" = _: {};
              "Mod+Alt+Shift+Ctrl+Up"."move-column-to-monitor-up" = _: {};
              "Mod+Alt+Shift+Ctrl+Down"."move-column-to-monitor-down" = _: {};

              # Layout controls.
              "Mod+Alt+Ctrl+F"."expand-column-to-available-width" = _: {};
              "Mod+Alt+C"."center-column" = _: {};
              "Mod+Alt+Ctrl+C"."center-visible-columns" = _: {};
              "Mod+Alt+Minus"."set-column-width" = "-10%";
              "Mod+Alt+Equal"."set-column-width" = "+10%";
              "Mod+Alt+Shift+Minus"."set-window-height" = "-10%";
              "Mod+Alt+Shift+Equal"."set-window-height" = "+10%";

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
            # Numbered and lettered workspace access on Mod/Super.
            // (lib.mapAttrs' (k: v: lib.nameValuePair "Mod+${k}" v) modWorkspaceFocus)
            // (lib.mapAttrs' (k: v: lib.nameValuePair "Mod+Shift+${k}" v) modWorkspaceMove)
            // (lib.mapAttrs' (k: v: lib.nameValuePair "Mod+${lib.toUpper k}" v) modWorkspaceFocusLetters)
            // (lib.mapAttrs' (k: v: lib.nameValuePair "Mod+Shift+${lib.toUpper k}" v) modWorkspaceMoveLetters);
        };
      };
    };
}
