# frozen_string_literal: true

require 'json'

require 'vagrant/ansible_auto'

describe 'CLI: ansible inventory', component: 'cli/ansible-inventory' do
  include_context 'acceptance'

  def execute_ansible_inventory(*args)
    execute('vagrant', 'ansible', 'inventory', *args)
  end

  def assert_execute_ansible_inventory(*args)
    assert_execute('vagrant', 'ansible', 'inventory', *args)
  end

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

  context 'given the --ini option' do
    it 'returns the inventory as INI' do
      result = assert_execute_ansible_inventory('--ini')
      [
        /^ansible-test-control\s+/,
        /^ansible-test-worker-1\s+/,
        /^ansible-test-worker-2\s+/,
        /^\[control\]\s*$/,
        /^\[worker\]\s*$/
      ].each do |regex|
        expect(result.stdout).to match regex
      end
    end
  end

  context 'given the --json option' do
    it 'returns the inventory as terse JSON' do
      result = assert_execute_ansible_inventory('--json')
      expect(result.stdout.lines.count).to be == 1
      expect { JSON.parse(result.stdout.strip) }.not_to raise_error
    end
  end

  context 'given the --pretty option' do
    it 'returns the inventory as pretty JSON' do
      result = assert_execute_ansible_inventory('--pretty')
      expect(result.stdout.lines.count).to be > 1
      expect { JSON.parse(result.stdout.strip) }.not_to raise_error
    end
  end

  context 'given the --help option' do
    let!(:help_output) { assert_execute_ansible_inventory('--help').stdout }

    it 'prints a usage message' do
      expect(help_output).to match_output(:inventory_usage)
    end

    it 'prints an available options stanza' do
      expect(help_output).to match_output(:inventory_available_options)
    end

    %w[ini json pretty].each do |type|
      it "prints a usage message for the --#{type} option" do
        expect(help_output).to match_output(:"inventory_option_#{type}")
      end
    end
  end
end
