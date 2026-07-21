#!/usr/bin/env bash

######################################################################
# OS-level security hardening (firewall, mandatory access control, etc.)
######################################################################
# Not meant to be run directly - sourced by build_ubuntu.sh, after util.sh.
######################################################################

# Ubuntu ships AppArmor installed and enabled by default, but this makes
# that explicit and idempotent instead of relying on it silently staying
# that way. apparmor-utils adds aa-status/aa-enforce/aa-complain for
# inspecting and managing profiles by hand later.
enable_apparmor() {
  sudo apt-get --yes install apparmor apparmor-utils
  sudo systemctl enable --now apparmor
}

# Installs UFW and turns it on with low-verbosity logging - default deny
# incoming, default allow outgoing. Idempotent - install/enable/logging
# are all safe to run repeatedly.
#
# Other useful commands, run by hand as needed:
#   sudo ufw status verbose
#   sudo ufw logging off
#   sudo ufw disable
#   sudo ufw reset
#   sudo ufw show raw
enable_ufw() {
  sudo apt-get --yes install ufw
  sudo ufw enable
  sudo ufw logging low
}

# Installs fail2ban and starts it, ahead of need - its stock jail.conf
# ships every jail (sshd included) disabled until you enable one in
# jail.local against a service that's actually installed, so this is a
# no-op today but means adding e.g. openssh-server later doesn't also
# require remembering to come back and add fail2ban.
enable_fail2ban() {
  sudo apt-get --yes install fail2ban
  sudo systemctl enable --now fail2ban
}
