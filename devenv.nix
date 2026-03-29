{ pkgs, lib, config, inputs, ... }:

let
  pkgs-stable = import inputs.nixpkgs-stable { system = pkgs.stdenv.system; };
  pkgs-unstable = import inputs.nixpkgs-unstable { system = pkgs.stdenv.system; };
in
{
  env.GREET = "Flutter APP Template";

  packages = with pkgs-stable; [
    git
    figlet
    lolcat
    watchman
    inotify-tools
    # Linux desktop build & runtime dependencies
    pkg-config
    gtk3
    glib
    libsecret
    sqlite
    cmake
    ninja
    clang
  ];

  android = {
    enable = true;
    flutter.enable = true;
    flutter.package = pkgs-unstable.flutter;
  };

  scripts.hello.exec = ''
    figlet -w 120 $GREET | lolcat
  '';

  enterShell = ''
    hello
  '';

}

