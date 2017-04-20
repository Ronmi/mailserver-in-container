Secure, *relatively* easy to setup public mail server.

# Howto

## Setup DNS records

You should add at least 3 `SRV` records and a `TXT` record:

```dns
mail             $TTL IN A   1.2.3.4
_imap._tcp       $TTL IN SRV 0 0 993 mail
_imaps._tcp      $TTL IN SRV 0 0 993 mail
_submission._tcp $TTL IN SRV 0 0 587 mail
@                $TTL IN TXT "v=spf1 ip4:1.2.3.4 ~all"
```

It's not necessary to use `mail.your.domain` like above. You can freely choose better name for your mail server, or even use `@`.

## Setup mail server with docker

You'll have to get `docker` and `docker-compose` installed first.

### Prepare environment

```sh
# generate required file for nginx SSL
$ openssl dhparam -out data/dhparams.pem 2048

# grab newest phppostadmin code
#     with wget
$ wget -q -O - https://github.com/postfixadmin/postfixadmin/archive/master.tar.gz | tar zxf - --strip-component 1 -C data/postadmin
#     or curl
$ curl -sSL https://github.com/postfixadmin/postfixadmin/archive/master.tar.gz | tar zxf - --strip-component 1 -C data/postadmin

# initialize database
$ docker-compose up -d mysql
# wait a moment, let mysql work
# create necessary database structure
$ docker-compose exec mysql prepare_db.sh
```

### Copy you SSL certificate/key

```sh
cp /path/to/your/fullchain.pem data/cert/mail.pem
cp /path/to/your/privatekey.pem data/cert/mail.key
```

or

### Obtain one using certbot

```sh
$ docker-compose run certbot certbot certonly --manual --cert-name mail
# make symlink for nginx/postfix/dovecot
$ cd data
$ ln -s live/mail/fullchain.pem mail.pem
$ ln -s live/mail/privkey.pem mail.key
```

### Run it!

```sh
$ docker-compose up -d
```

### Configure postadmin

For security consideration, port of nginx is not exported by default. You have to:

1. Lookup the ip address of nginx container `docker-compose exec nginx ip addr`
2. Find your way to reach that ip, ssh port-forwarding for example
3. Open `setup.php` in browser, say, `http://127.0.0.1:8000/setup.php` if forwarded to localhost:8000 via ssh
4. Open `index.php` and configure your mailboxes

### Ready to use

Now your mail server should be well-configured. It's up to you to edit `docker-compose.yml` for exporting postadmin to public, or keep it secret for best security.
