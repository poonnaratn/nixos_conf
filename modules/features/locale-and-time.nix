{ ... }: {
  flake.nixosModules.localeAndTime = {
    time.timeZone = "Asia/Bangkok";

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
  };
}
