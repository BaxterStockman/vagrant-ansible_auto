# frozen_string_literal: true

require 'spec_helper'

require 'vagrant/ansible_auto/util/config'

describe VagrantPlugins::AnsibleAuto::Util::Config do
  let(:including_klass) do
    Class.new do
      include VagrantPlugins::AnsibleAuto::Util::Config
    end
  end

  before do
    stub_const("#{including_klass.name}::UNSET_VALUE", Object.new)
  end

  let(:including_instance) { including_klass.new }
  let(:unset_value) { including_klass.const_get :UNSET_VALUE }
  let(:unset_values) { [nil, @meh, unset_value] }

  describe '#unset?' do
    context 'given a nil value, undefined value, or the special UNSET_VALUE object' do
      it 'returns true' do
        expect(unset_values.map { |o| including_instance.unset? o }).to all(be true)
      end
    end

    context 'given anything else' do
      it 'returns false' do
        expect(['hey', 10, Object.new].map { |o| including_instance.unset? o }).to all(be false)
      end
    end
  end

  describe '#conditional_merge' do
    context 'given unset values in the first argument' do
      let(:righthand) { Object.new }

      it 'returns the second argument' do
        expect(unset_values.map { |o| including_instance.conditional_merge(o, righthand) }).to all(eq(righthand))
      end
    end

    context 'given unset values in the second argument' do
      let(:lefthand) { Object.new }

      it 'returns the second argument' do
        expect(unset_values.map { |o| including_instance.conditional_merge(lefthand, o) }).to all(eq(lefthand))
      end
    end

    context 'given two hashes' do
      let(:lefthand) { { a: 'hash', b: { real: 'dude' } } }
      let(:righthand) { { b: { real: 'calm', and: %w[do not move] }, c: 'you later' } }
      let(:merged) { { a: 'hash', b: { real: 'calm', and: %w[do not move] }, c: 'you later' } }

      it 'merges the second argument into the first' do
        expect(including_instance.conditional_merge(lefthand, righthand)).to eq(merged)
      end
    end
  end
end
