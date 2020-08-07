# frozen_string_literal: true

Vagrant::Spec::Acceptance.configure do |config|
  config.component_paths << 'spec/acceptance'
  config.skeleton_paths << 'spec/acceptance/support-skeletons'

  # Silence Vagrant's "You appear to be running Vagrant outside of the official
  # installers" message.  This message mucks up things like parsing the output
  # of `vagrant-skel` with JSON.load.  Also disable the bit that checks whether
  # a newer version of Vagrant is available, as it also breaks JSON.load.
  config.env.merge!(
    'VAGRANT_I_KNOW_WHAT_IM_DOING_PLEASE_BE_QUIET'  => '1',
    'VAGRANT_CHECKPOINT_DISABLE'                    => '1'
  )
end

# Pull in SimpleCov, Coveralls, and RSpec setup
require_relative 'spec/spec_helper'
