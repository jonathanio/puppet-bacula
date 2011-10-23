## bacula::storage
# Configure the Storage Daemon for Bacula, making sure we build the storage
# location and import all exported configuration files and directories for
# this server.

class bacula::storage {
  # Do the configuration checks before we continue
  require bacula::config

  # Make sure the Storage Daemon is installed (with sqlite3)
  package {
    ['bacula-sd-sqlite3']:
      ensure => 'latest';
  }

  # Configure the name and hostname for the Storage Daemon (i.e. this server)
  $safe_storage_hostname = $fqdn
  $safe_storage_name     = $hostname
  # And import the name of the Director from the node configuration
  $safe_director_hostname = $bacula_director_server
  $safe_director_name     = $bacula_director_server ? {
    /^([a-z0-9_-]+)\./ => $1,
    default            => $bacula_director_server
  }

  # Create the configuration for the Storage Daemon and make sure the directory
  # for the per-Client configuration is created before we run the realization
  # for the exported files below. Also make sure that the storage locations are
  # created along with the location for the default Device.
  file {
    '/etc/bacula/bacula-sd.conf':
      ensure  => 'present',
      owner   => 'bacula',
      group   => 'bacula',
      content => template('bacula/bacula-sd.conf'),
      notify  => Service['bacula-sd'],
      require => Package['bacula-sd-sqlite3'];
    '/etc/bacula/bacula-sd.d':
      ensure  => 'directory',
      owner   => 'bacula',
      group   => 'bacula',
      require => Package['bacula-sd-sqlite3'];
  # Create an empty while which will make sure that the last line of
  # the bacula-sd.conf file will always run correctly.
    '/etc/bacula/bacula-sd.d/empty.conf':
      ensure  => 'present',
      owner   => 'bacula',
      group   => 'bacula',
      content => '# DO NOT EDIT - Managed by Puppet - DO NOT REMOVE',
      require => File['/etc/bacula/bacula-sd.d'];
   ['/mnt/bacula', '/mnt/bacula/default']:
      ensure  => 'directory',
      owner   => 'bacula',
      group   => 'tape',
      mode    => '0750';
  }

  # If TLS has been enabled, fetch the certifiate we need to secure the
  # connection to and from the Storage Daemon
  if ($safe_tls_enable) {
    file {
      '/etc/bacula/bacula-sd.pem':
        ensure  => 'present',
        source  => "puppet://$server/bacula/$bacula_tls_storagedaemon"
        owner   => 'bacula',
        group   => 'bacula',
        mode    => '0400',
        require => [ Package['bacula-sd-sqlite3'], File['/etc/bacula/ca.pem'] ];
    }
  }

  # Register the Service so we can manage it through Puppet
  service {
    'bacula-sd':
      enable     => true,
      ensure     => running,
      require    => Package['bacula-sd-sqlite3'],
      hasstatus  => true,
      hasrestart => true;
  }

  # Finally, realise all the virtual exported configruation from the clients
  # that this server needs to be configured to manage
  File <<| tag == "bacula_storage_$safe_storage_name" |>>
}
