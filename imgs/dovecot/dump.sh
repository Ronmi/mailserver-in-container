#!/bin/bash
### BEGIN INIT INFO
# Provides:       dumping
# Required-Start:
# Required-Stop:
# X-Start-Before: rsyslog fail2ban
# X-Stop-After:
# Non-Stop:       yes
### END INIT INFO

# this is for fail2ban
if [[ ! -f /var/log/mail.warn ]]
then
    touch /var/log/mail.warn
    chown root:adm /var/log/mail.warn
fi

rm -f /run/dump
mkfifo /run/dump
cat /run/dump
