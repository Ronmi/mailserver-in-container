#!/bin/bash
### BEGIN INIT INFO
# Provides:       init
# Required-Start:
# Required-Stop:
# X-Start-Before: cron spamassassin
# X-Stop-After:
# Non-Stop:
### END INIT INFO

SAHOME=/var/lib/spamassassin
PZHOME="${SAHOME}/pyzor"

# Create pyzor directory if not exists
if [[ ! -d "$PZHOME" ]]
then
    mkdir -p "$PZHOME"
fi

# Ensure file permissions
chown -R debian-spamd:debian-spamd "$SAHOME"
chown -R vmail:vmail /home/vmail

# Initialize pyzor
su -c "/usr/bin/pyzor --homedir '$PZHOME' discover" debian-spamd
