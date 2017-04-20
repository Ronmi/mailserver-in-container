FROM ronmi/ynit-image

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
        certbot cron \
 && apt-get clean -y \
 && rm -fr /var/lib/apt/lists/*

RUN ln -sf /etc/init.d/cron /etc/ynit/

CMD ["ynit", "-unix", "/dev/log"]
