{ pkgs, lib, config, inputs, ... }:

let
  pkgs-stable = import inputs.nixpkgs-stable { system = pkgs.stdenv.system; };
  pkgs-unstable = import inputs.nixpkgs-unstable { system = pkgs.stdenv.system; };
in
{
  env.GREET = "Flutter APP Template";

  packages = [
    pkgs-stable.git
    pkgs-stable.figlet
    pkgs-stable.lolcat
    pkgs-stable.watchman
    pkgs-stable.inotify-tools
  ];

  languages.dart = {
    enable = true;
  };

  android = {
    enable = true;
    flutter.enable = true;
  };

  scripts.hello.exec = ''
    figlet -w 120 $GREET | lolcat
  '';

  enterShell = ''
    hello
  '';

}

