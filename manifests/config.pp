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

  # Work out if TLS needs to be enabled or not in the configuration
  $safe_tls_enable = $bacula_tls_enable {
    /^[Yy](?:es)?|1$/ => true,
    default           => false
  }

  # Because we need a series of 'self-signed' certificates to enable TLS
  # support between the different parts of the Bacula System, and there
  # is no easy way to have the certificates created and signed on a
  # central machine and distributed, we'll do a little cheat.
  #
  # Bacula doesn't require the FQDN to be the Common Name on a certificate,
  # only that the certificate can be verified by a known Cerificate Authority
  # file, and optionally that the Common Name that is on the certificate has
  # been specifically allowed.
  #
  # Therefore, each group of servers will be set up with four basic
  # certificates; one for each of the components in the system.
  #
  # TODO: Possibly allow an override for the Director component on the
  #       different parts to allow for custom certificates for managing
  #       Console access?
  if ($safe_tls_enable) {
    # First up, make sure that the CA File is specified so that
    # all the components can verfy the different certificates
    if ($bacula_tls_ca != /^[\w_\.-]+\.pem$/i) {
      warn("Invalid (or missing) CA File setting for Bacula")
    }

    # Then, check we have a valid configuration for the base name for the
    # certificate's Common Name - we won't use the domain part of the FDDN
    # as that can change between machines.
    if ($bacula_tls_base != /^[a-z0-9_-]+(\.[a-z0-9_-]+)+$/) {
      warn("Invalid (or missing) Common Name base setting: $bacula_tls_base")
    }

    # Next, check we have a name for the director certificate
    if ($bacula_tls_director != /^[\w_\.-]+\.pem$/i) {
      warn("Invalid (or missing) Director Certificate setting for Bacula: $bacula_tls_director")
    }
    # Plus one for the Storage Daemon
    if ($bacula_tls_storagedaemon != /^[\w_\.-]+\.pem$/i) {
      warn("Invalid (or missing) Storage Daemon Certifiate setting for Bacula: $bacula_tls_storagedaemon")
    }
    # Another for the File Daemon
    if ($bacula_tls_filedaemon != /^[\w_\.-]+\.pem$/i) {
      warn("Invalid (or not set) File Daemon Certifiate setting for Bacula: $bacula_tls_filedaemon")
    }
    # And finally, one for Console access
    if ($bacula_tls_console != /^[\w_\.-]+\.pem$/i) {
      warn("Invalid (or not set) Console Certificate for Bacula: $bacula_tls_console")
    }

    # Now that we've checked everything, we need to save the CA File to the
    # system. But, as this file is common to all the components, we'll define
    # the file{} directive here so that we don't get conflicts when the
    # Director and Storage Daemon are on the same node.
    file {
      # TODO: This may be an issue as we cannot check if the /etc/bacular
      #       directory exists before installing it? We cannot depend on
      #       bacula-common as that needs to be pulled in by the different
      #       parts of the system using the packages required by each
      "/etc/bacula/ca.pem":
        ensure  => 'present',
        source  => "puppet://$server/bacula/$bacula_tls_ca",
        owner   => 'bacula',
        group   => 'bacula',
        mode    => '0400';
    }
  }
}
