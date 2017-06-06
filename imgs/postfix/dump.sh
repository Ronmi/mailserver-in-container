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
for i in $(grep -F var/log/mail /etc/rsyslog.conf | awk '{print $2}' | sed -E 's/^-//')
do
    if [[ ! -f "$i" ]]
    then
	touch "$i"
	chown root:adm "$i"
    fi
done

rm -f /run/dump
mkfifo /run/dump
cat /run/dump
