{
  description = "Kovaxs Darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs, nix-homebrew }:
  let
    configuration = { pkgs, config,  ... }: {
      # List packages installed in system profile. To search by name, run:
      # $ nix-env -qaP | grep wget
      nixpkgs.config.allowUnfree=true;
      # nixpkgs.config.allowUnsupportedSystem = true;

      environment.systemPackages = [
        pkgs.lua51Packages.lua
        pkgs.devenv
        pkgs.nodejs_22
        pkgs.mkalias
        # pkgs.cargo
        # pkgs.rustc
        # pkgs.rustup
        pkgs.adwaita-icon-theme
        pkgs.ansible
        pkgs.ansible-lint
        pkgs.at-spi2-core
        pkgs.bat
        pkgs.btop
        pkgs.iproute2mac
        pkgs.fd
        pkgs.ffmpeg
        pkgs.ffmpegthumbnailer
        pkgs.fontforge
        pkgs.fzf
        pkgs.ghostscript
        pkgs.girara
        pkgs.gimp
        pkgs.git
        pkgs.git-lfs
        pkgs.glow
        pkgs.graphviz
        pkgs.gtk3
        pkgs.htop
        pkgs.httpie
        pkgs.imagemagick
        pkgs.irssi
        pkgs.jq
        pkgs.k9s
        pkgs.kind
        pkgs.lazygit
        pkgs.lazydocker
        pkgs.librsvg
        pkgs.luarocks
        pkgs.ncdu
        # pkgs.neovim
        pkgs.uv
        pkgs.nmap
        pkgs.pkg-config
        pkgs.poppler
        pkgs.portaudio
        pkgs.pstree
        pkgs.ripgrep
        pkgs.sphinx
        pkgs.texliveFull
        pkgs.tmux
        pkgs.tree
        pkgs.watch
        pkgs.wget
        pkgs.xclip
        pkgs.yazi
        pkgs.zathura
        pkgs.zoxide
        pkgs.dbeaver-bin
        pkgs.inkscape
        pkgs.obsidian
        pkgs.wireshark
        pkgs.vlc-bin
        pkgs.podman
        pkgs.fzf
   ];

    homebrew = {
                    enable = true;
                    taps = [
                        "nikitabobko/tap"
                    ];
                    casks = [
                       "alacritty"
                        "keycastr"
                        "libreoffice"
                        "nikitabobko/tap/aerospace"
                        "sioyek"
                    ];
                    brews = [
                        "libmagic"
                        "cmake"
                        "bash"
                        "mas"
                        "tesseract"
                        "neovim"
                        "nvtop"
                        "ruff"
                        "pyright"
                        "lua-language-server"
                    ];
                    masApps = {
                        "Telegram" = 747648890;

                    };
                    onActivation.cleanup = "zap";
                    onActivation.autoUpdate = true;
                    onActivation.upgrade = true;

                };


    # TODO: find out how to install my ComicSans fonts
    # https://nixos.wiki/wiki/Fonts

    fonts.packages = [
        pkgs.nerd-fonts.jetbrains-mono
    ];

    system.activationScripts.applications.text = let
      env = pkgs.buildEnv {
        name = "system-applications";
        paths = config.environment.systemPackages;
        pathsToLink = "/Applications";
      };
    in
      pkgs.lib.mkForce ''
      # Set up applications.
      echo "setting up /Applications..."
      rm -rf /Applications/Nix\ Apps
      mkdir -p /Applications/Nix\ Apps
      find ${env}/Applications -maxdepth 1 -type l -exec readlink '{}' + |
      while read -r src; do
        app_name=$(basename "$src")
        echo "copying $src" >&2
        ${pkgs.mkalias}/bin/mkalias "$src" "/Applications/Nix Apps/$app_name"
      done
          '';

    system.defaults = {
        dock.autohide = true;
    };

    # Necessary for using flakes on this system.
    nix.settings.experimental-features = "nix-command flakes";

    # Create /etc/zshrc that loads the nix-darwin environment.
    programs.zsh.enable = true;  # default shell on catalina
    # programs.fish.enable = true;
    # programs.bash.enable = true;

    # Set Git commit hash for darwin-version.
    system.configurationRevision = self.rev or self.dirtyRev or null;

    # Used for backwards compatibility, please read the changelog before changing.
    # $ darwin-rebuild changelog
    system.stateVersion = 5;

    # The platform the configuration will be used on.
    nixpkgs.hostPlatform = "aarch64-darwin";
    };
  in
  {
    # Build darwin flake using:
    # $ darwin-rebuild build --flake .#simple
    darwinConfigurations."kovaxs" = nix-darwin.lib.darwinSystem {
      modules = [
                    configuration
                    nix-homebrew.darwinModules.nix-homebrew
                    {
                        nix-homebrew = {
                            enable = true;
                            # Apple Silicon Only
                            enableRosetta = true;
                            # User owning the Homebrew prefix
                            user = "kovaxs";

                            autoMigrate = true;
                        };
                    }
                ];
    };

    # Expose the package set, including overlays, for convenience.
    darwinPackages = self.darwinConfigurations."kovaxs".pkgs;
  };
}
