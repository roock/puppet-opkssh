# opkssh

Puppet module to manage opkssh.

Have a look at [`REFERENCE.md`](REFERENCE.md) or the main module class
([`init.pp`](manifests/init.pp)) to see what this module does on a node plus
usage examples.

## Table of Contents

1. [Description](#description)
1. [Setup - The basics of getting started with opkssh](#setup)
    * [What opkssh affects](#what-opkssh-affects)
    * [Setup requirements](#setup-requirements)
    * [Beginning with opkssh](#beginning-with-opkssh)
1. [Usage - Configuration options and additional functionality](#usage)
1. [Limitations - OS compatibility, etc.](#limitations)
1. [Links](#links)
1. [Author](#author)

## Description

opkssh is a tool which enables ssh to be used with OpenID Connect allowing SSH access to be managed via identities like <alice@example.com> instead of long-lived SSH keys.

This module downloads the opkssh utility, manages the required configuration files
and configures ssh server to use opkssh.

## Setup

### What opkssh affects

* downloads opkssh binary
* manages opkssh configs & logfiles
* (optionally): update ssh server config tu use opkssh

### Setup Requirements

Requires augeas Sshd.lns.

### Beginning with opkssh

```puppet
include opkssh
```

Should be enough to install opkssh and configure ssh server.
The most minimal working config is:

## Usage

```puppet
  class { 'opkssh':
    auth_id_content => @("EOT"),
        # THIS FILE IS MANAGED BY PUPPET.
        # email/sub principal issuer
        alice alice@example.com https://accounts.google.com
        guest alice@example.com https://accounts.google.com
        root alice@example.com https://accounts.google.com
        dev bob@microsoft.com https://login.microsoftonline.com/9188040d-6c67-4c5b-b112-36a304b66dad/v2.0
        | EOT
    providers_content => @("EOT"),
        # Issuer Client-ID expiration-policy
        https://accounts.google.com 206584157355-7cbe4s640tvm7naoludob4ut1emii7sf.apps.googleusercontent.com 24h
        https://login.microsoftonline.com/9188040d-6c67-4c5b-b112-36a304b66dad/v2.0 096ce0a3-5e72-4da8-9c86-12924b294a01 24h
        | EOT
  }
```

See the [opkssh documentation](https://github.com/openpubkey/opkssh#server-configuration) about the contents of the files.

## Limitations

* Does not manage SELinux settings for opkssh
* Supports downloading amd64 and arm64 binaries
* Only tested on Debian/Ubuntu
* Probably doesn't work when you require a proxy for downloading

## Links

* Official opkssh website <https://github.com/openpubkey/opkssh>
* Official project page <https://github.com/roock/puppet-opkssh>

## Author

* Written initially by Roman Pertl <roman@pertl.org> @roock
