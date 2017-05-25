FROM ronmi/ynit-image

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
        dovecot-antispam dovecot-imapd dovecot-lmtpd dovecot-mysql dovecot-pop3d \
 && apt-get clean -y \
 && rm -fr /var/lib/apt/lists/* \
 && ln -sf /etc/init.d/dovecot /etc/ynit/

RUN addgroup --gid 5000 vmail \
 && adduser --home /home/vmail --no-create-home --uid 5000 --gid 5000 \
            --disabled-login --disabled-password --gecos ,,,,, \
	    vmail

ADD dovecot /etc/dovecot/
 
CMD ["ynit", "-unix", "/dev/log"]
