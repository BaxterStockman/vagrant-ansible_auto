# frozen_string_literal: true

require 'vagrant-spec/acceptance/output'

require 'vagrant/ansible_auto/command/root'
require 'vagrant/ansible_auto/errors'
require 'vagrant/ansible_auto/plugin'

VagrantPlugins::AnsibleAuto::Plugin.init!

module Vagrant
  module Spec
    OutputTester[:bad_extension] = lambda do |text|
      text =~ Regexp.new(Regexp.escape(VagrantPlugins::AnsibleAuto::Errors::BadExtensionError.new.message))
    end

    %w[synopsis usage available_subcommands subcommand_help].each do |trk|
      OutputTester[:"root_#{trk.tr('.', '_')}"] = lambda do |text|
        text =~ Regexp.new(Regexp.escape(I18n.t("vagrant.ansible_auto.command.root.#{trk}")))
      end
    end
  end
end
