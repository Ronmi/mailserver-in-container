#!/bin/bash
### BEGIN INIT INFO
# Provides:       dumping
# Required-Start:
# Required-Stop:
# X-Start-Before: rsyslog fail2ban
# X-Stop-After:
# Non-Stop:       yes
### END INIT INFO

touch /var/log/auth.log
rm -f /run/dump
mkfifo /run/dump
cat /run/dump
