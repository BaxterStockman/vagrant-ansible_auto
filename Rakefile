# frozen_string_literal: true

require 'bundler/gem_tasks'

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec).tap do |rspec_task|
  rspec_task.pattern = './spec/unit{,/*/**}/*_spec.rb'
end

require 'rubocop/rake_task'
RuboCop::RakeTask.new

require 'yard'
YARD::Rake::YardocTask.new

desc 'Run vagrant-spec'
namespace 'vagrant-spec' do
  desc 'Output vagrant-spec components'
  task :components do
    sh('vagrant-spec', 'components')
  end

  desc 'Run vagrant-spec tests'
  task :test do
    sh('vagrant-spec', 'test', '--components=cli/ansible-inventory')
  end
end

task default: %i[rubocop spec vagrant-spec:test]
