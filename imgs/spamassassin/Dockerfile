FROM ronmi/ynit-image

RUN apt-get update \
 && apt-get install -y --no-install-recommends spamassassin cron \
 && apt-get clean -y \
 && rm -fr /var/lib/apt/lists/*
 
RUN sed -i 's#OPTIONS="#OPTIONS="-A 0.0.0.0/0 -s /dev/stdout -l -i 0.0.0.0:9000 #' /etc/default/spamassassin \
 && sed -i 's/CRON=0/CRON=1/' /etc/default/spamassassin \
 && sed -i 's/ENABLED=0/ENABLED=1/' /etc/default/spamassassin

ADD local.cf /etc/spamassassin/

RUN ln -sf /etc/init.d/cron /etc/init.d/spamassassin /etc/ynit

CMD ["ynit", "-unix", "/dev/log"]
