FROM ronmi/ynit-image

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
        postfix-cdb postfix-mysql postfix-pcre postfix spamc \
 && apt-get clean -y \
 && rm -fr /var/lib/apt/lists/* \
 && ln -sf /etc/init.d/postfix /etc/ynit/
 
CMD ["ynit", "-unix", "/dev/log"]
