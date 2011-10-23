## bacula::console
# Configure the basic Bacula Console program.

class bacula::console {
  # Do the configuration checks before we continue
  require bacula::config

  # Make sure the Console package is installed
  package {
    ['bacula-console']:
      ensure => 'latest';
  }

  # Import the name of the Director from the node configuration
  $safe_director_hostname = $bacula_director_server
  $safe_director_name     = $bacula_director_server ? {
    /^([a-z0-9_-]+)\./ => $1,
    default            => $bacula_director_server
  }

  # Using the above settings (and $bacula_console_password), write
  # the configuration for bacula-console (bconsole)
  file {
    '/etc/bacula/bconsole.conf':
      ensure  => 'present',
      owner   => 'bacula',
      group   => 'bacula',
      content => template('bacula/bconsole.conf'),
      require => Package['bacula-console'];
  }

  # If TLS has been enabled, fetch the certifiate we need to secure the
  # connection from Bacula Console (in this case, it's mainly for
  # validation between the Console & the Director than securing)
  if ($safe_tls_enable) {
    file {
      '/etc/bacula/bconsole.pem':
        ensure  => 'present',
        source  => "puppet://$server/bacula/$bacula_tls_console"
        owner   => 'bacula',
        group   => 'bacula',
        mode    => '0400',
        require => [ Package['bacula-console'], File['/etc/bacula/ca.pem'] ];
    }
  }
}
