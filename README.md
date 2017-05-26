*Aim to be* secure, *relatively* easy to setup mail server.

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
# grab newest PostfixAdmin code
#     with wget
$ wget -q -O - https://github.com/postfixadmin/postfixadmin/archive/master.tar.gz | tar zxf - --strip-component 1 -C data/postadmin
#     or curl
$ curl -sSL https://github.com/postfixadmin/postfixadmin/archive/master.tar.gz | tar zxf - --strip-component 1 -C data/postadmin

# initialize database
$ docker-compose up -d mysql
# wait a moment, let MySQL work
# create necessary database structure
$ docker-compose exec mysql prepare_db.sh

# update maildir owner
$ sudo chown -R 5000:5000 data/mail
```

**Optional:**, you can install PHP-based application (like webmail) in `data/webmail`

### Copy you SSL certificate/key

```sh
cp /path/to/your/fullchain.pem data/cert/mail.pem
cp /path/to/your/privatekey.pem data/cert/mail.key
```

or

### Obtain one using Certbot

```sh
# If in doubt, visit letsencrypt.org for detailed usage
$ docker-compose run certbot certbot certonly --manual --cert-name mail
# make symlink for Postfix/Dovecot (you might need root privilege)
$ cd data/cert
$ ln -s live/mail/fullchain.pem mail.pem
$ ln -s live/mail/privkey.pem mail.key
```

### Configure PostfixAdmin

By default, the web service is exported at port 20007 without SSL. **You should make some protections** (eg: add firewall rules) before configuring PostfixAdmin.

First, bring up related services

```sh
$ docker-compose up -d nginx php mysql
```

1. Open `setup.php` in browser, say, `http://1.2.3.4:20007/setup.php`
2. Follow the instruction to
   1. Setup a **setup password**
   2. Modify `data/config.inc.php` for your setup password
   3. Create an administrator account
3. Open `index.php` and configure your mailboxes

### Bringing up whole service

```sh
$ docker-compose up -d
```

### Ready to use

Now your mail server should be well-configured. It's up to you to edit `docker-compose.yml` for exporting PostfixAdmin to public, or keep it secret for best security.

## Tips

### Usage

- You can use *WEBROOT* method to authenticate with Certbot, `/known` is there for you. This is the method I prefer.
- Wanna modify some settings? Use `docker cp` to make a copy at host side, and modify `docker-compose.yml` to mount it into container again.
- Migrating these servers to another VPS service? Just stop the server and tar the whole folder to new VPS, then `docker-compose up -d` again.

### Security

- Edit `docker-compose.yml` and/or firewall rules, do not expose the PostfixAdmin ui to public.
- If you have to expose it, https will always be a good idea.
- I am not an expert at this domain. It would be nice if willing to provide better configuration options via issue.
- Never forget applying security update. A simple command do the magic for you: `docker-compose pull && docker-compose build --pull && docker-compose up -d`

# TODO

- [ ] Add a job in cron.daily to run `sa-learn` with user-defined mail folder.
- [ ] Find a better way for PostfixAdmin installation.
- [ ] Add instructions for installing a webmail client, maybe RainLoop or Roundcube.

# LICENSE

MIT
