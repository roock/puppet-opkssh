# frozen_string_literal: true

require 'voxpupuli/acceptance/spec_helper_acceptance'

configure_beaker do |host|
  host.install_package('puppet-bolt') if bolt_supported?(host)
end
