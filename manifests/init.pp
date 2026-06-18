# Class: opkssh::init
# @summery
# Installs and configures opkssh.
# 
# This class is intended to be included on nodes requiring opkssh setup.
#
# @example
#  class { 'opkssh':
#    auth_id_content => @("EOT"),
#        # THIS FILE IS MANAGED BY PUPPET.
#        # email/sub principal issuer
#        alice alice@example.com https://accounts.google.com
#        guest alice@example.com https://accounts.google.com
#        root alice@example.com https://accounts.google.com
#        dev bob@microsoft.com https://login.microsoftonline.com/9188040d-6c67-4c5b-b112-36a304b66dad/v2.0
#        | EOT
#    providers_content => @("EOT"),
#        # Issuer Client-ID expiration-policy
#        https://accounts.google.com 206584157355-7cbe4s640tvm7naoludob4ut1emii7sf.apps.googleusercontent.com 24h
#        https://login.microsoftonline.com/9188040d-6c67-4c5b-b112-36a304b66dad/v2.0 096ce0a3-5e72-4da8-9c86-12924b294a01 24h
#        | EOT
#  }
# @param 
# @param [Optional[Boolean]] enable
#   install and enable or uninstall and disable exporter

# @param user The user used to install and run opkssh
# @param group The group used to install and run opkssh
# @param uid The user id used to install and run opkssh
# @param gid The group id userd to install and run opkssh
# @param system_user If the user for opkssh should be created as system user
# @param logfile_group The group of the logfile e.g. that other users can read the logfile without root permissions
# @param version The version of opkssh to install
# @param install_dir The directory to install opkssh into
# @param etc_path  The directory to write configs to
# @param configure_sshd If sshd config should be adopted to use opkssh
# @param reload_sshd If sshd service should be reloaded after changing the config
# @param download_url The download URL for the opkssh binary. If provided, takes priority over download_base
# @param download_base The base URL for downloading opkssh. Used with version to construct full URL. Ignored if download_url is specified
# @param checksum The checksum type to use when downloading the opkssh binary
# @param auth_id_content The contents of the opkssh auth_id file
# @param config_content The contents of the opkssh config file
# @param providers_content The contents of the opkssh providers file
class opkssh (
  String $user            = 'opksshuser',
  String $group           = 'opksshuser',
  Optional[Integer] $uid            = undef,
  Optional[Integer] $gid            = undef,
  Boolean $system_user     = true,
  String $logfile_group   = 'adm',
  String $version         = '0.14.0',
  String $install_dir     = '/opt/opkssh',
  String $etc_path        = '/etc',
  Boolean $configure_sshd = true,
  Boolean $reload_sshd    = true,
  Optional[String] $download_url = undef,
  Optional[String] $download_base = undef,
  Optional[String] $checksum      = undef,
  Optional[String] $auth_id_content = undef,
  Optional[String] $config_content = undef,
  Optional[String] $providers_content = undef,
) {
  group { $group:
    ensure => present,
    gid    => $gid,
    system => $system_user,
  }

  user { $user:
    ensure => present,
    uid    => $uid,
    groups => $group,
    system => $system_user,
    home   => "/home/${user}",
    shell  => '/bin/false',
  }

  file { $install_dir:
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }

  $binary_name = 'opkssh-linux-amd64'
  $url         = $download_url ? {
    undef => $download_base ? {
      undef   => "https://github.com/openpubkey/opkssh/releases/download/v${version}/${binary_name}",
      default => "${download_base}/v${version}/${binary_name}",
    },
    default => $download_url,
  }

  file { "${install_dir}/opkssh":
    ensure   => file,
    source   => $url,
    checksum => $checksum,
    owner    => 'root',
    group    => $group,
    mode     => '0755',
    require  => File[$install_dir],
  }

  $notify_setting = $reload_sshd ? {
    true    => Exec['reload_sshd'],
    default => undef,
  }

  if $configure_sshd {
    augeas { 'sshd_authorizedkeyscommanduser':
      context => '/files/etc/ssh/sshd_config',
      changes => [
        "set AuthorizedKeysCommandUser ${user}",
        "set AuthorizedKeysCommand '${install_dir}/opkssh verify %u %k %t'",
      ],
      lens    => 'Sshd.lns',
      incl    => '/etc/ssh/sshd_config',
      notify  => $notify_setting,
    }
  }

  exec { 'reload_sshd':
    command     => '/bin/systemctl reload sshd.service',
    refreshonly => true,
  }

  # TODO: add sudoers entry for the opkssh user if necessary
  # $AUTH_CMD_USER ALL=(ALL) NOPASSWD: ${INSTALL_DIR}/${BINARY_NAME} readhome *

  file { "${etc_path}/opk":
    ensure => directory,
    owner  => 'root',
    group  => $group,
    mode   => '0750',
  }

  file { "${etc_path}/opk/policy.d":
    ensure  => directory,
    owner   => 'root',
    group   => $group,
    mode    => '0750',
    require => File["${etc_path}/opk"],
  }

  file { "${etc_path}/opk/auth_id":
    ensure  => file,
    owner   => 'root',
    group   => $group,
    mode    => '0640',
    content => $auth_id_content,
    require => File["${etc_path}/opk"],
  }

  file { "${etc_path}/opk/config.yml":
    ensure  => file,
    owner   => 'root',
    group   => $group,
    mode    => '0640',
    content => $config_content,
    require => File["${etc_path}/opk"],
  }

  file { "${etc_path}/opk/providers":
    ensure  => file,
    owner   => 'root',
    group   => $group,
    mode    => '0640',
    content => $providers_content,
    require => File["${etc_path}/opk"],
  }

  file { '/var/log/opkssh.log':
    ensure => file,
    owner  => $user,
    group  => $logfile_group,
    mode   => '0640',
  }
}
