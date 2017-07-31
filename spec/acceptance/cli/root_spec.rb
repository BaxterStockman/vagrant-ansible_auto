# frozen_string_literal: true

require 'vagrant/ansible_auto'

describe 'CLI: ansible', component: 'cli/ansible' do
  include_context 'acceptance'

  around do |ex|
    begin
      saved_env = ENV.to_h
      ENV['VAGRANT_CWD'] = environment.workdir.to_s
      environment.skeleton('cli/ansible-inventory')
      ex.run
    ensure
      ENV.replace(saved_env)
    end
  end

  context 'given the --help option' do
    let!(:help_output) { assert_execute('vagrant', 'ansible', '--help').stdout }

    it 'prints a usage message' do
      expect(help_output).to match_output(:root_usage)
    end

    it 'prints an available subcommands stanza' do
      expect(help_output).to match_output(:root_available_subcommands)
    end

    it 'indicates where to get help on subcommand usage' do
      expect(help_output).to match_output(:root_subcommand_help)
    end
  end

  context 'given the list-commands vagrant command' do
    it 'displays a synopsis' do
      expect(assert_execute('vagrant', 'list-commands').stdout).to match_output(:root_synopsis)
    end
  end
end
