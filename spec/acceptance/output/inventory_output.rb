# frozen_string_literal: true

require 'vagrant-spec/acceptance/output'

require 'vagrant/ansible_auto/command/inventory'
require 'vagrant/ansible_auto/errors'
require 'vagrant/ansible_auto/plugin'

VagrantPlugins::AnsibleAuto::Plugin.init!

module Vagrant
  module Spec
    OutputTester[:bad_extension] = lambda do |text|
      text =~ Regexp.new(Regexp.escape(VagrantPlugins::AnsibleAuto::Errors::BadExtensionError.new.message))
    end

    %w[synopsis usage available_options option.ini option.json option.pretty diag.not_running].each do |trk|
      OutputTester[:"inventory_#{trk.tr('.', '_')}"] = lambda do |text|
        text =~ Regexp.new(Regexp.escape(I18n.t("vagrant.ansible_auto.command.inventory.#{trk}")))
      end
    end
  end
end
