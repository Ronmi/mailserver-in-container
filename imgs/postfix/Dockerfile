FROM ronmi/ynit-image

RUN echo "postfix postfix/mailname string postfix" | debconf-set-selections \
 && echo "postfix postfix/main_mailer_type string 'Internet Site'" | debconf-set-selections
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
        postfix-cdb postfix-mysql postfix-pcre postfix \
	spamc rsyslog iptables fail2ban \
 && apt-get clean -y \
 && rm -fr /var/lib/apt/lists/* \
 && ln -sf /etc/init.d/postfix /etc/init.d/rsyslog /etc/init.d/fail2ban /etc/ynit/
 
RUN addgroup --gid 5000 vmail \
 && adduser --home /home/vmail --no-create-home --uid 5000 --gid 5000 \
            --disabled-login --disabled-password --gecos ,,,,, \
	    vmail

ADD postfix /etc/postfix/
ADD dump.sh /etc/ynit/
ADD dump.conf /etc/rsyslog.d/

CMD ["ynit", "-unix", "/dev/log"]
