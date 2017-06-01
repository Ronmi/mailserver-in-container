*Aim to be* secure, *relatively* easy to setup mail server.

It is designed for personal or small business only.

# What's inside

- Postfix for sending mail, with SSL/STARTTLS support.
- Dovecot for receiving mail, with SSL support.
- SpamAssassin for spam detection, with per-user based bayes filter.
- Automatically learning for spam detection:
  * Move mail to `Spam` or `Junk` folder for reporting to SpamAssassin as spam.
  * Move mail from `Spam` or `Junk` folder for reporting to SpamAssassin as normal mail.
- Certbot to obtain free SSL certification, with auto-renewal.
- PostfixAdmin for easier administrating.
- Webmail-ready (PHP-based), install RainLoop/Roundcube/whatever you want in a jiffy.

### Pros

- **Relatively easy** to install: less than 5 mins with fast internet connection. (using installation script)
- Easy to backup and migrate: just stop the whole service and `sudo tar` it. (need root privilege for preserving owner info)
- Easy to configure: using PostfixAdmin to provide web-based administration.
- Build on top of Debian: applying security updates only costs you one line of code; Better stability (comparing with Ubuntu)

### Cons

- Still needs lots learning to keep things running well (tuning configurations in particular)
- You'll need to execute few tasks manually, obtain your SSL certifiacte for example.
- Fat and furious; Higher risk about 0-day attack (Debian is not that fast in this domain).

# Howto

## Setup DNS records

Since DNSSEC is required to send mail to many public mail services like Gmail, it is suggested not to host your own DNS unless you know what you are doing.

You should add at least 3 `SRV` records and a `TXT` record:

```dns
mail             $TTL IN A   1.2.3.4
_imap._tcp       $TTL IN SRV 0 0 993 mail
_imaps._tcp      $TTL IN SRV 0 0 993 mail
_submission._tcp $TTL IN SRV 0 0 587 mail
@                $TTL IN TXT "v=spf1 ip4:1.2.3.4 ~all"
```

It's not necessary to use `mail.your.domain` like above. You can freely choose better name for your mail server, or even use `@`.

## Prepare your SSL certificate

The Postfix and Dovecot are preconfigured to use SSL/TLS only, you have to obtain a certificate for it.

### Copy you SSL certificate/key

Buy/apply one from somewhere (maybe your domain name seller?), then

```sh
cp /path/to/your/fullchain.pem data/cert/mail.pem
cp /path/to/your/privatekey.pem data/cert/mail.key
```

**or**

### Obtain one free with Certbot

Below are steps using `WEBROOT` method. You can find more information about Certbot on the internet.

First, you should modify the `docker-compose.yml` for exposing NGINX at port 80, or set a reverse proxy in front of it.

After that

```sh
# If in doubt, visit letsencrypt.org for detailed usage
$ docker-compose run certbot certbot certonly --webroot /known -d mail.your.domain -d another_host.your.domain --cert-name mail
# make symlink for Postfix/Dovecot (you might need root privilege)
$ cd data/cert
$ ln -s live/mail/fullchain.pem mail.pem
$ ln -s live/mail/privkey.pem mail.key
```

## Setup mail server with docker

You'll have to get `docker` and `docker-compose` installed first.

Following is manual setup method. If you are quite familiar with this, you might want to run `./install.sh` for a faster installation.

### Prepare environment

```sh
# initialize database
$ docker-compose up -d mysql
# wait a moment, let MySQL work
# create necessary database structure
$ docker-compose exec mysql prepare_db.sh

# update maildir owner
$ sudo chown -R 5000:5000 data/mail
```

**Optional:**, you can install PHP-based application (like webmail) in `data/webmail`

### Install PostfixAdmin

By default, the web service is exported at port 20007 without SSL. **You should make some protections** (e.g., add firewall rules) before configuring PostfixAdmin.

First, grab newest PostfixAdmin codes

```sh
# grab newest PostfixAdmin code
#     with wget
$ wget -q -O - https://github.com/postfixadmin/postfixadmin/archive/master.tar.gz | tar zxf - --strip-component 1 -C data/postadmin
#     or curl
$ curl -sSL https://github.com/postfixadmin/postfixadmin/archive/master.tar.gz | tar zxf - --strip-component 1 -C data/postadmin

# copy default config file for PostfixAdmin
$ cp data/config.inc.php data/postadmin/
```

Bring up related services

```sh
$ docker-compose up -d nginx php mysql
```

1. Open `setup.php` in browser, say, `http://1.2.3.4:20007/setup.php`
2. Follow the instruction to
   1. Setup a **setup password**
   2. Modify `data/postadmin/config.inc.php` for your setup password
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
- Never forget applying security update. A simple command do the magic for you:
  * `docker-compose pull && docker-compose build --no-cache --pull && docker-compose up -d` for a complete rebuild (**Suggested**)
  * `docker-compose pull && docker-compose build --pull && docker-compose up -d` for a faster rebuild (Rely on Docker's official image)

# LICENSE

MIT
