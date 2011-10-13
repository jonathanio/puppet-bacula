puppet-bacula
=============

by Jonathan Wright <jonathan@netwrker.co.uk>
Copyright (c) 2011, Jonathan Wright.


ABOUT
=====

This module is designed to be used with Puppet to configure Bacula to backup servers across a local area network. It has separate classes for configuring a Director, one or more Storage Daemons and File Daemons (Clients) along with the bconsole and bat programs (for local workstations).

You can manage multiple networks of Bacula within an operation should you require, however each Storage Daemon, File Daemon and Console/BAT can only be configured with a single Director. In theory this will probably be enough for most networks.


LICENCE
-------

puppet-bacula is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

puppet-bacula is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with puppet-bacula.  If not, see <http://www.gnu.org/licenses/>.


TODO
----

 * Enable support for dymanic creation of `FileSet`'s based on support for the variables `$bacula_backup_include` and `$bacula_backup_exclude` so that you can add and/or remove some directories for individual hosts.
 * This configuration is known to known to only work with Debian-based distributions. There is nothing within it allow it to work between different distributions at this time. Feel free to submit changes to allow this to function across different distributions as required.
 * This configuration will also operate using SQLite3 only. At this point its been designed to work with a simple network, as so SQLite3 will be enough for this time. Feel free to submit additions to help with MySQL and/or PostgreSQL.
 * Fill in anything in this documentation I've forgotten about...


CONFIGURATION
=============

There are two steps to the configuration of Bacula using this module:

 1. Configure the Envionment Variables to define what will be backing up and to where, which which passwords and reporting to whom.
 2. Configure the nodes with the required classes to act as the different parts of the network.

The environment variables are as follows:

```ruby
$bacula_server_password  = "random_password_one_goes_here"
$bacula_console_password = "random_password_two_goes_here"
$bacula_director_server  = "director.bacula.local"
$bacula_storage_server   = "storage.bacula.local"
$bacula_mail_to          = "example@example.com"
```

The only one that isn't required is the last one - if not yet, the e-mails will simply be sent to 'root' by default. If you require something more useful, set it with this.

Otherwise, the variables are fairly simple - set the FQDN of the Director which will manage backing up across the network, along with the FQDN of the Storage Daemon which the servers will back up to. You can have as many Storage Daemons as you require, configured as you see fit. For example, you could have the master one if the global namespace, then override servers individually, or in groups through the inherit mechinism.

The Director must also have a Storage Daemon listed as this is the default Storage Deamon for all jobs (overriden as required by each of the nodes to be backed up) and also will be the Storage Daemon to which the Catalog/Database will be backed up.

```ruby
$bacula_backup_dohome    = 'No'                          # 'Yes' or 'No'
$bacula_backup_onday     = 'Saturday'                    # Days of the Week
# You can also extend the include/exclude lists on a per-node or groups-of-nodes basis:
$bacula_backup_includes  = ['/path/one', '/path/two']    # Default is Empty
$bacula_backup_excludes  = ['/path/three', '/path/four'] # Default is Empty
```

These variables are optional, with the defaults as shown. If you want to spread out the days on which full backups occur, or if you need to backup the /home directory on one or more boxes, or if you have specific locations you need to back up as well, then you can managed all these from these four variables.

The variables `$bacula_backup_includes` and `$bacula_backup_excludes` will, if specificed, create a dedicated `FileSet` for this host and write an override into the per-Client configuration for the Director.


From there, just add the classes to the node you want backed up:

```puppet
node basenode {
  $bacula_server_password  = "random_password_one_goes_here"
  $bacula_console_password = "random_password_two_goes_here"
  $bacula_director_server  = "director.bacula.local"
  $bacula_storage_server   = "storage.bacula.local"
  $bacula_mail_to          = "example@example.com"
}

node director inherits basenode {
  include bacula::director, bacula::console
}

node storage inherits basenode {
  include bacula::storage
}

node www1, www2, www3, www4 inherits basenode {
  include bacula
}

node more-storage inherits basenode {
  include bacula::storage
}

node www5, www6, www7, www8 inherits basenode {
  $bacula_storage_servers = "more-storage.bacula.local"
  include bacula
}

node nfs inherits basenode {
  $bacula_backup_dohome='Yes'
  $bacula_backup_onday='Friday'
  include bacula
}

node desktop inherits basenode {
  include bacula::bat
}
```

Once configured, run `puppet agent` on each of the servers to be backed up (`www[0-8]`) and this will export resources (make sure that `storeconfigs = true` is set in the 'puppet.conf' of your 'puppetmasterd') to be run and/or saves on the required servers. Then run it on your Director and Storage Daemons (order here doesn't matter). Puppet will then install a base configuration and export any of the relevent resources it can find.

This also means that any time you install a new server to be backed up, e.g. `www9`, you need to run `puppet agent` on `www9` first to set up the File Daemon, then run it on the Director and Storage Daemon to install the configuration they require for that server.


DEFAULTS
--------

 * A server will be have a full backup on Saturday, of which the first of the month will be a *Full* backup and the other Saturday's being *Differential* (only changes since the last Full or Differential Backup). All mid-week backups will be *Incremental*.
 * All *Incremental* backups will be made at *20:00*, with *Full* backups starting at *18:30* (or *15:30* on Saturday or Sunday).
 * All servers will *not* have their '/home' directory backed up. The assumption is that this is mounted via NFS from a central location and therefore you will use `$bacula_backup_dohome` on the NFS server to back this up as required.
 * The default `FileSet` is as follows:

```
FileSet {
  Name = "Basic:noHome"
  Include {
    File = /boot
    File = /etc
    File = /usr/local
    File = /var
    File = /opt
    File = /srv
  }

  Exclude {
    File = /var/cache
    File = /var/tmp
    File = /var/lib/dpkg
    File = /var/lib/puppet
    File = /var/lib/mysql
    File = /var/lib/postgresql
    File = /var/lib/ldap
    File = /var/lib/bacula
  }
}
```

NOTES
=====

 * I haven't created an environment variable to configure the location of the storage as it's not managed by the `bacula::storage` class, but by the `bacula` class - effectively each File Daemon creates it's own location to be added onto the Storage Daemon as part of the resource exporting. This is required so that we create individual `Device`'s for each host so that it will support concurrent streams of data. So long as we only have a single `Device` on a Storage Daemon we can only support a single stream. By fixing it in the code it keeps out issues of changes mid-installation. All Devices will created under `/mnt/bacula/${FQDN}`, so mount your backup file space as `/mnt/bacula` on all Storage Nodes.
 * This hasn't yet been tested extensivley (at this point it only has only completed a few successful first-full runs). I will monitor it over the coming weeks and months to make sure that its behaving as I would expect and make any changes required.
 * There is no requirement to have separate Director and Storage Daemon nodes. This module is perfectly happy with having both on the same box. The only restriction is that you cannot install the File Deamon (`include bacula`) on the same box that runs the Director (`include bacula::director`). The Director class installs it's own copy of the File Daemon to manage the backing up of Catalog and this will fail with the `Package['bacula-fd']` having already been defined.
 * Finally, across a Puppet network, the hostnames (for FQDN's) of the Directors, and Storage Daemons must be unique. You cannot at this time have 'director.bacula.com' and 'director.bacula.net' as they will be both processed as just 'director' in parts of the configuration. If there is a pressing need for full FQDN's across all parts of the configuration I will make the changes, but I don't see the need for it at the moment.


HELP
====

If you have issues with this or can think of ways to improve this, fork or raise an issue. I'm more than happy for others to help out as required. This has been created for a specific need in my office enviroment and therefore it does fit that need. If others can expand on it or improve, I welcome your input!
