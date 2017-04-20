FROM ronmi/ynit-image

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
        dovecot-antispam dovecot-imapd dovecot-lmtpd dovecot-mysql dovecot-pop3d \
 && apt-get clean -y \
 && rm -fr /var/lib/apt/lists/* \
 && ln -sf /etc/init.d/dovecot /etc/ynit/
 
CMD ["ynit", "-unix", "/dev/log"]
