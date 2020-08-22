{ pkgs ? import <nixpkgs> {}
, ruby ? pkgs.ruby
, installPlugins ? false
}:

let
  ruby' = if pkgs.lib.isString ruby then pkgs.${ruby} else ruby;
in (import ./. { inherit pkgs; }).mkVagrantAnsibleAutoShell {
  ruby = ruby';
  inherit installPlugins;
}
