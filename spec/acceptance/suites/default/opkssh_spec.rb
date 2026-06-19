# frozen_string_literal: true

require 'spec_helper_acceptance'

describe 'opkssh' do
  describe 'default configuration' do
    it_behaves_like 'an idempotent resource' do
      let(:manifest) { 'include opkssh' }
    end

    describe command('/opt/opkssh/opkssh --version') do
      its(:stdout) { is_expected.to match(%r{^opkssh version}) }
    end

    describe file('/etc/ssh/sshd_config') do
      its(:content) { is_expected.to match(%r{^AuthorizedKeysCommandUser opksshuser$}) }
      its(:content) { is_expected.to match(%r{^AuthorizedKeysCommand /opt/opkssh/opkssh verify %u %k %t$}) }
    end
  end

  describe 'with download_base parameter' do
    it_behaves_like 'an idempotent resource' do
      let(:manifest) do
        <<-MANIFEST
          class { 'opkssh':
            version       => '0.13.0',
            download_base => 'https://github.com/openpubkey/opkssh/releases/download',
          }
        MANIFEST
      end
    end

    describe command('/opt/opkssh/opkssh --version') do
      its(:stdout) { is_expected.to match(%r{^opkssh version}) }
    end

    describe file('/etc/ssh/sshd_config') do
      its(:content) { is_expected.to match(%r{^AuthorizedKeysCommandUser opksshuser$}) }
    end
  end

  describe 'with download_url parameter (takes priority)' do
    it_behaves_like 'an idempotent resource' do
      let(:manifest) do
        <<-MANIFEST
          class { 'opkssh':
            download_url  => 'https://github.com/openpubkey/opkssh/releases/download/v0.13.0/opkssh-linux-amd64',
            download_base => 'https://ignored.example.com',
          }
        MANIFEST
      end
    end

    describe command('/opt/opkssh/opkssh --version') do
      its(:stdout) { is_expected.to match(%r{^opkssh version}) }
    end

    describe file('/etc/ssh/sshd_config') do
      its(:content) { is_expected.to match(%r{^AuthorizedKeysCommandUser opksshuser$}) }
    end
  end
end
