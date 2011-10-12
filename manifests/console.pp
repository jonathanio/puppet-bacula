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
}
