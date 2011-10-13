## bacula
# This is the per-Client class and will configure the File Daemon to run on
# the server so that the Director can talk to it to back it up, while also
# producing and exporting the required configuration for the Director and
# the Storage Daemon as well so that they can be configured with the required
# settings on those boxes as well.

class bacula {
  # Do the configuration checks before we continue
  require bacula::config

  # Make sure the File Daemon (the client program) is installed. Don't use the
  # bacula-client package as it pulls in console and additional stuff which
  # we don't require
  package {
    ['bacula-fd']:
      ensure => 'latest';
  }

  # Import the name and the hostname for the Directory from the node settings
  $safe_director_hostname = $bacula_director_server
  $safe_director_name     = $bacula_director_server ? {
    /^([a-z0-9_-]+)\./ => "$1",
    default            => $bacula_director_server
  }
  # And do the same for the Storage Daemon
  $safe_storage_hostname = $bacula_storage_server
  $safe_storage_name     = $bacula_storage_server ? {
    /^([a-z0-9_-]+)\./ => "$1",
    default            => $bacula_storage_server
  }
  # Finally also set up the name and hostname for the Client itself
  $safe_client_hostname = $fqdn
  $safe_client_name     = $hostname

  # Make sure that we have a numeric priority between 1 and 1000; default is 15
  $safe_priority = $bacula_priority ? {
    /^(1000|[1-9][0-9]{2}|[1-9][0-9]|[1-9])$/ => $bacula_priority,
    default                                   => 15
  }

  # Make sure that the backup day is valid
  $safe_backup_onday = $bacula_backup_onday ? {
    /^([Mm]on|[Tt]ues|[Ww]ednes|[Tt]hurs|[Ff]ri|[Ss]atur|[Ss]un)day$/ => $bacula_backup_onday,
    default                                                           => 'Saturday'
  }

  # Also work out if we'll be backing up the home directory on this server too
  # (the default will be no, as /home will be mounted from an NFS server)
  $safe_backup_dohome = $bacula_backup_dohome ? {
    /^([Yy](es)?|1)$/ => 'withHome',
    default           => 'noHome'
  }

  # Create various instances of the configuration required to get this server to
  # be backed up. Once is for the Director, which will initiate the backups and
  # set what needs to be backed up (and to where) and the other is for the
  # Storage Daemon, which will set where on it's filesystem the backups will be
  # kept (for which we'll also create a command which will make sure that
  # location exists)
  @@file {
    "/etc/bacula/bacula-dir.d/$safe_client_name.conf":
      ensure  => 'present',
      owner   => 'bacula',
      group   => 'bacula',
      mode    => '0640',
      tag     => "bacula_director_$safe_director_name",
      content => template('bacula/host-dir.conf'),
      notify  => Service['bacula-director'],
      require => File['/etc/bacula/bacula-dir.d'];
    "/etc/bacula/bacula-sd.d/$safe_client_name.conf":
      ensure  => 'present',
      owner   => 'bacula',
      group   => 'bacula',
      mode    => '0640',
      tag     => "bacula_storage_$safe_storage_name",
      content => template('bacula/host-sd.conf'),
      notify  => Service['bacula-sd'],
      require => File['/etc/bacula/bacula-sd.d'];
    "/mnt/bacula/$safe_client_hostname":
      ensure  => 'directory',
      tag     => "bacula_storage_$safe_storage_name",
      owner   => 'bacula',
      group   => 'tape',
      mode    => '0750',
      require => File['/mnt/bacula'];
  }

  # Register the Service so we can manage it through Puppet
  service {
    'bacula-fd':
      enable     => true,
      ensure     => running,
      require    => Package['bacula-fd'],
      hasrestart => true;
  }

  # Finally, make sure that the configuration for the client itself is set so
  # that it will allow the Director to talk with it and that it can contact
  # the Storage Daemon to back up the data
  file {
    '/etc/bacula/bacula-fd.conf':
      ensure  => 'present',
      content => template('bacula/bacula-fd.conf'),
      notify  => Service['bacula-fd'],
      require => Package['bacula-fd'];
  }
}
