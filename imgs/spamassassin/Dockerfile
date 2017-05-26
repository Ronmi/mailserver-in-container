FROM ronmi/ynit-image

RUN apt-get update \
 && apt-get install -y spamassassin cron pyzor \
 && apt-get clean -y \
 && rm -fr /var/lib/apt/lists/*
 
RUN sed -i 's#OPTIONS="#OPTIONS="-A 0.0.0.0/0 -s /dev/stdout -l -i 0.0.0.0:9000 #' /etc/default/spamassassin \
 && sed -i 's/CRON=0/CRON=1/' /etc/default/spamassassin \
 && sed -i 's/ENABLED=0/ENABLED=1/' /etc/default/spamassassin

RUN addgroup --gid 5000 vmail \
 && adduser --home /home/vmail --no-create-home --uid 5000 --gid 5000 \
            --disabled-login --disabled-password --gecos ,,,,, \
	    vmail

ADD local.cf /etc/spamassassin/
ADD prepare.sh /etc/ynit/

RUN ln -sf /etc/init.d/cron /etc/init.d/spamassassin /etc/ynit

CMD ["ynit", "-unix", "/dev/log"]
