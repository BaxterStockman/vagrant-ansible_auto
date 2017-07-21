# frozen_string_literal: true

require 'pathname'

Pathname.new(__FILE__).tap do |helper|
  $LOAD_PATH.unshift((helper.parent.parent + 'lib').to_s)

  require 'vagrant/ansible_auto'

  helper.parent.join('support').find { |f| require f if f.extname == '.rb' }
end

SimpleCov.start
