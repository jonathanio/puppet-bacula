## bacula::bat
# Configure the graphical Bacula Console program (which will take most of its
# work from the bacula::console class rather than re-rolling it's own).

class bacula::bat inherits bacula::console {
  # The config check will be done by bacula::console (not this class)

  # Make sure the graphical Bacula Console package is installed
  package {
    ['bacula-console-qt']:
      ensure => 'latest';
  }

  # Set the configuration file for the graphical console to just be a symlink
  # to the bconsole.conf file as it will contain the same data
  file {
    '/etc/bacula/bat.conf':
      ensure  => 'symlink',
      target  => 'bconsole.conf',
      require => [ Package['bacula-console-qt'], File['/etc/bacula/bconsole.conf'] ];
  }
}
