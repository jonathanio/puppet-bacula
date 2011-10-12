## bacula::config
# Perform some basic config checks on the configuration data when any
# of the bacula::* classes are called.

class bacula::config {
  # Check both the Director configuration variables to make sure that it is
  # a fully-qualified domain name
  if ($bacula_director_server !~ /^[a-z0-9_-]+(\.[a-z0-9_-]+){2,}$/) {
    fail("Invalid Bacula Director: $bacula_director_server")
  }
  # Do the same for the Storage Daemon configuration variable
  if ($bacula_storage_server !~ /^[a-z0-9_-]+(\.[a-z0-9_-]+){2,}$/) {
    fail("Invalid Bacula Storage Daemon: $bacula_storage_server")
  }
  # Make sure we have vales for both the Password variables
  if ($bacula_server_password == "" or $bacula_console_password == "") {
    fail("Bacula Server Password and/or Console Password is/are not set")
  }

  # Set up some default environment variables that are common to all versions
  # of the classes, first of which is the e-mail address we will send e-mails to
  $safe_mail_to = $bacula_mail_to ? {
    /^[\w-]+@([\w-]+\.)+[\w-]+$/ => $bacula_mail_to,
    default                      => "root@$domain"
  }
}
