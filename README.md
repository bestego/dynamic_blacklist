# dynamic_blacklist
Dynamically adapts firewall against unwanted external access.

The program scans the systems log files for unwanted access and blocks corresponding IP addresses when number of occurences exceed a limit.

# Prerequisite
This program is designed for & tested on Ubuntu systems.
It requires usage of *ufw* firewall.

# Installation
Download this program in some temporary_directory.
```
cd temporary_directory
sudo ./install.sh
```
Installation script will prompt for installation directories for binary files and for configuration files.

After successful intallation, downloaded program may be deleted.

# Configuration / Deployment
Make sure installation directory for binaries is included in PATH environmental variable.
In the directory for configuration files:
* edit *dbl.cfg* to your needs
* include LAN IP segment into whitelist (optionally: include trusted hosts)
* the *dbl.d* directory contains scripts ending at .sh ; Each script performs a specific check in a specific system log file. It may be necessary to change/add/delete scripts depending on your syste setup and needs.

# Usage
As user root, run:
  ```dynamic_blacklist configuration_directory```
Typically: let cron execute this script on a regular bases, e.g. every 15 minutes

# Testing
Test files are included in download.
**Prerequisite:** *bats-core* needs to be downloaded from GitHub and installed on your system
```
cd temporary_directory
bats test
```
