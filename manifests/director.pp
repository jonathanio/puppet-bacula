## bacula::director
# Configure the Director for Bacula, making sure that all the client
# configuration is imported as required for this server.

class bacula::director inherits bacula::config {

  # Make sure the Director is installed (with sqlite3, which will be used for
  # the storage of the Catalog data). We will also need the File Daemon client
  # on this server regardless to manage backups of the Catalog
  package {
    ['bacula-director-sqlite3', 'bacula-fd']:
      ensure => 'latest';
  }

  # Configure the name and the hostname for the Director (i.e. this server)
  # and also set it to be the Client name/hostname as well for the File Deamon
  $safe_director_hostname = $fqdn
  $safe_director_name     = $hostname
  $safe_client_hostname   = $fqdn
  $safe_client_name       = $hostname
  # And import the details for the *DEFAULT* Storage Daemon, which will provide
  # the default storage Device and Pool configuration. Each client will be able
  # to define their own Storage Daemons if required and they will be imported
  # later on in the per-Client configuration
  $safe_storage_hostname = $bacula_storage_server
  $safe_storage_name     = $bacula_storage_server ? {
    /^([a-z0-9_-]+)\./ => $1,
    default            => $bacula_storage_server
  }

  # Create the configuration for the Director and make sure the directory for
  # the per-Client configuration is created before we run the realization for
  # the exported files below
  file {
    '/etc/bacula/bacula-dir.conf':
      ensure  => 'present',
      owner   => 'bacula',
      group   => 'bacula',
      content => template('bacula/bacula-dir.conf'),
      notify  => Service['bacula-director'],
      require => Package['bacula-director-sqlite3'];
    '/etc/bacula/bacula-dir.d':
      ensure  => 'directory',
      owner   => 'bacula',
      group   => 'bacula',
      require => Package['bacula-director-sqlite3'];
  # Create an empty while which will make sure that the last line of
  # the bacula-dir.conf file will always run correctly.
    '/etc/bacula/bacula-dir.d/empty.conf':
      ensure  => 'present',
      owner   => 'bacula',
      group   => 'bacula',
      content => '# DO NOT EDIT - Managed by Puppet - DO NOT REMOVE',
      require => File['/etc/bacula/bacula-dir.d'];
  # Add in the configuration for the File Daemon (nothing special is needed
  # for this server, so we'll continue to use the default configuration)
    '/etc/bacula/bacula-fd.conf':
      ensure  => 'present',
      owner   => 'bacula',
      group   => 'bacula',
      content => template('bacula/bacula-fd.conf'),
      notify  => Service['bacula-fd'],
      require => Package['bacula-fd'];
  }

  # Register the Service so we can manage it through Puppet
  service {
    'bacula-director':
      enable     => true,
      ensure     => running,
      require    => Package['bacula-director-sqlite3'],
      hasstatus  => true,
      hasrestart => true;
    'bacula-fd':
      enable     => true,
      ensure     => running,
      require    => Package['bacula-fd'],
      hasrestart => true;
  }

  # Finally, realise all the virtual files created by all the clients that
  # this server needs to be configured to manage
  File <<| tag == "bacula_director_$safe_director_name" |>>
}
