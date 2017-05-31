FROM ronmi/ynit-image:stretch

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
        dovecot-imapd dovecot-lmtpd dovecot-mysql dovecot-pop3d \
        dovecot-sieve spamc \
 && apt-get clean -y \
 && rm -fr /var/lib/apt/lists/* \
 && ln -sf /etc/init.d/dovecot /etc/ynit/

RUN addgroup --gid 5000 vmail \
 && adduser --home /home/vmail --no-create-home --uid 5000 --gid 5000 \
            --disabled-login --disabled-password --gecos ,,,,, \
	    vmail

ADD dovecot /etc/dovecot/
RUN echo 'postmaster_address = root@localhost' | tee -a /etc/dovecot/dovecot.conf

ADD sieve /usr/lib/dovecot/sieve/
RUN sievec /usr/lib/dovecot/sieve/report-spam.sieve \
 && sievec /usr/lib/dovecot/sieve/report-ham.sieve
 
CMD ["ynit", "-unix", "/dev/log"]
