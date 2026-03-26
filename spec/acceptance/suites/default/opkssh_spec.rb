# frozen_string_literal: true

require 'spec_helper_acceptance'

describe 'opkssh' do
  it_behaves_like 'an idempotent resource' do
    let(:manifest) { 'include opkssh' }
  end

  # Apply twice to ensure no errors the second time.
  apply_manifest(pp, catch_failures: true)
  apply_manifest(pp, catch_changes: true)
  #   end

  describe command('/opt/opkssh/opkssh --version') do
    its(:stdout) { is_expected.to match(%r{^opkssh version}) }
  end

  describe file('/etc/ssh/sshd_config') do
    its(:content) { is_expected.to match(%r{^AuthorizedKeysCommandUser opksshuser$}) }
    its(:content) { is_expected.to match(%r{^AuthorizedKeysCommand /opt/opkssh/opkssh verify %u %k %t$}) }
  end
end
