FROM ronmi/ynit-image

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
        cron fetchmail ca-certificates \
        libdbi-perl libmime-base64-perl libfile-temp-perl \
	libsys-syslog-perl liblockfile-simple-perl \
 && apt-get clean -y \
 && rm -fr /var/lib/apt/lists/*
 
RUN addgroup --gid 5000 vmail \
 && adduser --home /home/vmail --no-create-home --uid 5000 --gid 5000 \
            --disabled-login --disabled-password --gecos ,,,,, \
	    vmail

RUN mkdir /run/fetchmail && chown vmail:vmail /run/fetchmail

ADD fetchmail /etc/cron.d/

RUN ln -sf /etc/init.d/cron /etc/ynit

CMD ["ynit", "-unix", "/dev/log"]
