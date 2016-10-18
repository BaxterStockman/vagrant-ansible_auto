require 'pathname'

$LOAD_PATH.unshift (Pathname.new(__FILE__).parent.parent + 'lib').to_s

require 'vagrant/ansible_inventory'

# We're using an older version of rspec-expectations that doesn't have the
# `all' matcher.
RSpec::Matchers.define :all do |expected|
  define_method :index_failed_objects do |actual|
  end

  def index_failed_objects(actual)
    return enum_for(__method__, actual) unless block_given?

    @failed_items = []

    actual.each_with_index do |o, i|
      @failed_items[i] = yield o
    end

    @failed_items.compact.empty?
  end

  match_for_should do |actual|
    index_failed_objects(actual) do |item|
      expected.failure_message_for_should unless expected.matches?(item)
    end
  end

  match_for_should_not do |actual|
    index_failed_objects(actual) do |item|
      expected.failure_message_for_should_not if expected.matches?(item)
    end
  end

  def failure_message(actual)
    unless actual.respond_to?(:each_with_index)
      "provided object is not iterable"
    else
      @failed_items.each_with_index.reject { |f, i| f.nil? }.map do |f, i|
        "object at index #{i} failed to match: #{f}"
      end.join("\n")
    end
  end

  failure_message_for_should      { |actual| failure_message(actual) }
  failure_message_for_should_not  { |actual| failure_message(actual) }
end

shared_context 'machine' do
  let(:machine) { double('machine') }
  let(:state) { double('state') }
  let(:ssh_info) { Hash.new }

  before do
    machine.stub(ssh_info: ssh_info, state: state)
    machine.stub(name: 'mymachine')
    state.stub(id: :running)
    allow(ssh_info).to receive(:[])
    allow(ssh_info).to receive(:fetch).with(:private_key_path, anything).and_return([])
  end
end

shared_context 'host' do
  require 'vagrant/ansible_inventory/host'

  include_context 'machine'

  let(:host) { VagrantPlugins::AnsibleInventory::Host.new(machine) }
end

shared_context 'inventory' do
  require 'vagrant/ansible_inventory/host'

  include_context 'machine'

  let(:inventory) { VagrantPlugins::AnsibleInventory.new }
end
