FROM ronmi/ynit-image

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
        postfix-cdb postfix-mysql postfix-pcre postfix spamc \
 && apt-get clean -y \
 && rm -fr /var/lib/apt/lists/* \
 && ln -sf /etc/init.d/postfix /etc/ynit/
 
RUN addgroup --gid 5000 vmail \
 && adduser --home /home/vmail --no-create-home --uid 5000 --gid 5000 \
            --disabled-login --disabled-password --gecos ,,,,, \
	    vmail

ADD postfix /etc/postfix/

CMD ["ynit", "-unix", "/dev/log"]
