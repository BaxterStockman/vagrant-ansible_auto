{ pkgs ? import <nixpkgs> {} }:

with pkgs;

let
  mkVagrantAnsibleAutoShell = { ruby, installPlugins ? false }: let
    buildRubyGem = pkgs.buildRubyGem.override {
      inherit ruby;
    };
    bundler = pkgs.bundler.override {
      inherit ruby buildRubyGem;
    };
  in mkShell {
    name = "vagrant-ansible_auto-${ruby.name}";

    buildInputs = [
      ruby
      bundler
      vagrant
    ];

    VAGRANT_HOME = toString (./. + "/.vagrant/ansible_auto/${vagrant.version}");

    shellHook = lib.optionalString installPlugins ''
      bundle exec rake build
      vagrant plugin install "$(
        ${findutils}/bin/find ${lib.escapeShellArg (toString ./pkg)} -name '*.gem' -print0 \
          | ${coreutils}/bin/sort --reverse --version-sort -z \
          | ${coreutils}/bin/head -z -n 1
      )"
    '';
  };
in {
  inherit mkVagrantAnsibleAutoShell;
}
