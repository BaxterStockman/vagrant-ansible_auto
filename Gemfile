# frozen_string_literal: true

source 'https://rubygems.org'

group :development do
  gem 'pry'
  gem 'vagrant', github: 'mitchellh/vagrant', tag: 'v2.1.5'
  # Lock to commit just before update to rspec ~> 3.5.0, which broke the whole
  # dang thing :(
  gem 'vagrant-spec', github: 'mitchellh/vagrant-spec', ref: '2f0fb10'
end

group :plugins do
  gemspec
end
