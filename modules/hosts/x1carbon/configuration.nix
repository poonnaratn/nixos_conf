{ self, inputs, ... }: {

  flake.nixosModules.x1CarbonConfiguration = { pkgs, lib, ... }: {
    # import any other modules from here
    imports = [
      self.nixosModules.x1CarbonHardware
      self.nixosModules.keyboard
      #self.nixosModules.niri
    ];

	  nix.settings.experimental-features = [ "nix-command" "flakes" ];

	  # 32bits GUI
	  hardware.graphics.enable = true;
	  hardware.graphics.enable32Bit = true;

	  # Enable Buetooth
	  hardware.bluetooth.enable = true;

	  # Bootloader.
	  boot.loader.systemd-boot.enable = true;
	  boot.loader.efi.canTouchEfiVariables = true;

	  # Use latest kernel.
	  boot.kernelPackages = pkgs.linuxPackages_latest;

	  networking.hostName = "nixos"; # Define your hostname.
	  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

	  # Configure network proxy if necessary
	  # networking.proxy.default = "http://user:password@proxy:port/";
	  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

	  # Enable networking
	  networking.networkmanager.enable = true;

	  # Set your time zone.
	  time.timeZone = "Asia/Bangkok";

	  # Select internationalisation properties.
	  i18n.defaultLocale = "en_GB.UTF-8";

	  i18n.extraLocaleSettings = {
	    LC_ADDRESS = "th_TH.UTF-8";
	    LC_IDENTIFICATION = "th_TH.UTF-8";
	    LC_MEASUREMENT = "th_TH.UTF-8";
	    LC_MONETARY = "th_TH.UTF-8";
	    LC_NAME = "th_TH.UTF-8";
	    LC_NUMERIC = "th_TH.UTF-8";
	    LC_PAPER = "th_TH.UTF-8";
	    LC_TELEPHONE = "th_TH.UTF-8";
	    LC_TIME = "th_TH.UTF-8";
	  };

	  # Enable the X11 windowing system.
	  # You can disable this if you're only using the Wayland session.
	  services.xserver.enable = true;

	  # Enable the KDE Plasma Desktop Environment.
	  services.displayManager.sddm.enable = true;
	  services.desktopManager.plasma6.enable = true;

	  # Configure keymap in X11
	  services.xserver.xkb = {
	    layout = "us";
	    variant = "";
	  };

	  # Enable CUPS to print documents.
	  services.printing.enable = true;

	  # Enable sound with pipewire.
	  services.pulseaudio.enable = false;
	  security.rtkit.enable = true;
	  services.pipewire = {
	    enable = true;
	    alsa.enable = true;
	    alsa.support32Bit = true;
	    pulse.enable = true;
	    # If you want to use JACK applications, uncomment this
	    #jack.enable = true;

	    # use the example session manager (no others are packaged yet so this is enabled by default,
	    # no need to redefine it in your config for now)
	    #media-session.enable = true;
	  };

	  # Enable touchpad support (enabled default in most desktopManager).
	  # services.xserver.libinput.enable = true;

	  # Define a user account. Don't forget to set a password with ‘passwd’.
	  users.users.me = {
	    isNormalUser = true;
	    description = "me";
	    extraGroups = [ "networkmanager" "wheel" ];
	    packages = with pkgs; [
	    #  thunderbird
	    ];
	  };

	  # Install firefox.
	  programs.firefox.enable = true;

	  # Allow unfree packages
	  nixpkgs.config.allowUnfree = true;

	  # List packages installed in system profile. To search, run:
	  # $ nix search wget
	  environment.systemPackages = with pkgs; [
	    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
	    wget
	    discord-ptb
	    steam
	    git	
	    fzf
	    bruno
	    wl-clipboard
	  ];

	  programs.steam={
	    enable = true;
	    extraPackages = [ pkgs.adwaita-icon-theme ];
	  };

	  # Some programs need SUID wrappers, can be configured further or are
	  # started in user sessions.
	  # programs.mtr.enable = true;
	  # programs.gnupg.agent = {
	  #   enable = true;
	  #   enableSSHSupport = true;
	  # };

	  # List services that you want to enable:

	  # Enable the OpenSSH daemon.
	  # services.openssh.enable = true;

	  # Open ports in the firewall.
	  # networking.firewall.allowedTCPPorts = [ ... ];
	  # networking.firewall.allowedUDPPorts = [ ... ];
	  # Or disable the firewall altogether.
	  # networking.firewall.enable = false;

	  # This value determines the NixOS release from which the default
	  # settings for stateful data, like file locations and database versions
	  # on your system were taken. It‘s perfectly fine and recommended to leave
	  # this value at the release version of the first install of this system.
	  # Before changing this value read the documentation for this option
	  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
	  system.stateVersion = "25.11"; # Did you read the comment?

	  };
}
