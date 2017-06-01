#!/bin/bash

# Define constants
POSTADMIN_SRC=https://github.com/postfixadmin/postfixadmin/archive/master.tar.gz
RAINLOOP_SRC=https://www.rainloop.net/repository/webmail/rainloop-community-latest.zip

function log {
    echo -n "$* ... "
}

function msg_ignore {
    done="done."
    fail="failed."

    if [[ $2 != "" ]]
    then
	done="$2"
    fi

    if [[ $3 != "" ]]
    then
	fail="$3"
    fi

    if [[ $1 == 0 ]]
    then
	echo "$done"
    else
	echo "$fail"
    fi

    return $1
}

function msg {
    msg_ignore "$1" "$2" "$3"
    ERR=$?
    if [[ $ERR != 0 ]]
    then
	echo "$4"
	exit $ERR
    fi
}

function on_host {
    log 'Check for docker'
    which docker > /dev/null 2>&1
    msg $? '' '' 'You must install docker before running this script.'

    log 'Check for docker-compose'
    which docker-compose > /dev/null 2>&1
    msg $? '' '' 'You must install docker-compose before running this script.'

    log 'Check if we can create container'
    docker run -it --rm nginx bash -c 'echo 1' > /dev/null 2>&1
    msg $? '' '' 'You must have correct privilege to run this script. (maybe retry by sudo?)'

    log 'Preparing Certbot image for validating SSL cert settings'
    docker-compose build certbot > /dev/null 2>&1
    msg $?

    log 'Check for SSL certificate'
    docker-compose run --rm certbot test -e /etc/letsencrypt/mail.pem > /dev/null 2>&1
    msg $? mail.pem '' 'You have to prepare you SSL certificate before running this script'
    log 'Check for SSL private key'
    docker-compose run --rm certbot test -e /etc/letsencrypt/mail.key > /dev/null 2>&1
    msg $? mail.key '' 'You have to prepare you SSL certificate before running this script'

    log 'Detect uid of www-data in Nginx image'
    WWW_DATA_UID=$(docker run --rm nginx id -u www-data | head -n 1)
    WWW_DATA_GID=$(docker run --rm nginx id -g www-data | head -n 1)
    msg_ignore 0 $WWW_DATA_UID:$WWW_DATA_GID

    log 'Starting mysql'
    docker-compose up -d mysql > /dev/null 2>&1
    msg $?
    # wait 10s for mysql to init
    echo -n "Waiting for mysql server ..."
    sleep 10
    # run mysql command to see if it is done
    while true
    do
	sleep 1
	docker-compose exec mysql mysql -u root -psecretpassword -e 'select 1' > /dev/null 2>&1
	if [[ $? == 0 ]]
	then
	    break
	fi
	echo -n "."
    done
    msg 0
    # create database
    log 'Initialize database structure'
    docker-compose exec mysql prepare_db.sh > /dev/null 2>&1
    msg $?

    # create a container to run further
    echo "Entering container ... "
    docker run -it --rm -v "$(pwd):/data" \
	   -e WUID=${WWW_DATA_UID} \
	   -e WGID=${WWW_DATA_GID} \
	   -e "POSTPASS=${1}" \
	   -w /data \
	   php:7 /data/install.sh inside

    log 'Stop running containers'
    docker-compose down > /dev/null 2>&1
    msg 0

    log 'Build all container images'
    docker-compose build --pull > /dev/null 2>&1
    msg $?

    echo 'All done!

You have to manual config your mail server and webmail through
web ui:

1. Start all container using "docker-compose up -d".
2. Setup PostfixAdmin:
   * Navigate to "http://127.0.0.1:20007/_postadmin/setup.php"
     to create administrator account.
   * Navigate to "http://127.0.0.1:20007/_postadmin/index.php"
     for creating domains and mail accounts.
   * Since SHA-1 is not considered as secure now, I personally
     suggest you to remove "data/postadmin/setup.php" after
     creating administrator account.
3. Setup RainLoop:
   * Navigate to "http://127.0.0.1:20007/?admin", follow the
     instructions in RainLoop official document to set it up.
   * RainLoop official document about installation:
     https://www.rainloop.net/docs/configuration/

Happy Mailing!'
}

function in_container {
    # install required tools
    apt-get update
    apt-get install -y wget unzip

    # download PostfixAdmin
    (
	cd data/postadmin
	wget -q -O - https://github.com/postfixadmin/postfixadmin/archive/master.tar.gz | tar zxf - --strip-component 1
	chown -R ${WUID}:${WGID} .
	chmod -R go-w .
    )

    # download RainLoop
    (
	cd data/webmail
	wget -O downloaded.zip "$RAINLOOP_SRC"
	unzip downloaded.zip
	rm downloaded.zip
	chown -R ${WUID}:${WGID} .
	# fix permissions
	find . -type d -exec chmod 755 {} ';'
	find . -type f -exec chmod 644 {} ';'
	chmod -R go-rw data/
    )

    # configure PostfixAdmin
    cp data/config.inc.php data/postadmin/
    HASH=$((
	echo '<?php'
	echo -n '$pass = '
	echo "'${POSTPASS}';"
	echo '
$salt = time() . "*127.0.0.1*" . mt_rand(0, 60000);
$salt = md5($salt);
echo sprintf(
  "%s:%s",
  $salt,
  sha1($salt . ":" . $pass)
);
'
    ) | php)
    sed -i "s/changeme/$HASH/" data/postadmin/config.inc.php
    chmod 600 data/postadmin/config.inc.php
}

case "$1" in
    inside)
	in_container
	;;
    help|h|-h|-help|--help|"")
	echo "Usage: $0 postfixadmin_setup_password"
	echo ''
	echo 'PostfixAdmin needs your password to be'
	echo '  * Minimum length is 5.'
	echo '  * At least 3 characters.'
	echo '  * At least 2 digits.'
	echo ''
	echo 'You have to manually edit the data/config.inc.php'
	echo 'to loosen/tighten this restriction before running'
	echo 'this script.'
	exit 1
	;;
    *)
	on_host "$1"
	;;
esac
