You can create your own mail server in a jiffy.

# What's inside

* Preconfigured Postfix/Dovecot/SpamAssassin.
* Move mail from/to **Spam** folder to train bayers filter.
* Manage domains and mailboxes from web by PostfixAdmin.
* A webmail system powered by RainLoop community edition.
* [Certbot](https://letsencrypt.org)!!!

# Howto

Suppose you're doing these on a brand new machine.

## Obtain SSL certification with Certbot

### Enable NGINX for authenticating

Modify `docker-compose.yml`, expose NGINX service to port 80

```diff
-      - "127.0.0.1:20007:80"
+      - "80:80"
```

And bring it up

```sh
$ docker-compose up -d nginx
```

### Running cerbot to obtain certification

```sh
$ docker-compose run --rm certbot certonly --webroot /known -d mail.your.domain -d another.host -d another.domain --cert-name mail
```

You'll be asked for few questions for authenticating

Then, link the key and cert.

```sh
$ ln -s live/mail/fullchain.pem mail.pem
$ ln -s live/mail/privkey.pem mail.key
```

Certbot will periodically renewal your certification via cron.

## Running install script

PostfixAdmin needs your password to be:

* Minimum length is 5.
* At least 3 characters.
* At least 2 digits.

You have to manually edit the `data/config.inc.php` to loosen/tighten this restriction before running install script.

After deciding your setup_password, run `install.sh` with it:

```sh
$ ./install.sh my_secert_password_for_postfix_admin
```

## Bring up the whole service

```sh
$ docker-compose up -d
```

## Immediately configure RainLoop

RainLoop provides a defult administrator account `admin`/`12345`, which is **VERY** dangerous at this point.

Navigate to `http://mail.your.domain/?admin` to change password **IMMEDIATELY**!!!

## Configure PostfixAdmin

1. Navigate to `http://mail.your.domain/_postadmin/setup.php` and create an administrator account.
2. Use that account to log into `http://mail.your.domain/_postadmin/index.php` and setup mail domains and mailboxes.
3. Optionally, remove `data/postadmin/setup.php` to lower security risk a bit.

# Secure your web ui (optional)

By using HTTPS/HTTP2, your RainLoop/PostfixAdmin is free from fearing of MITM attack.

For best extensibility, I personally suggest you to host a reverse proxy in front of these docker service.

So we got to revert the settings of NGINX container back.

```sh
$ git checkout docker-compose.yml
$ docker-compose up -d nginx
```

As an example, I'll use NGINX on bare metal as reverse proxy below.

```sh
# install nginx (Debian for example)
$ apt-get install -y nginx-light
```

Create `dhparam.pem` for NGINX

```sh
$ openssl dhparam -out /etc/nginx/dhparams.pem 2048
```

And create a configuration file contains these

```nginx
server {
    server_name mail.* smtp.* imap.*;
    listen 80;

    location /.well-known/ {
        proxy_pass http://127.0.0.1:20007;
        include proxy_params;
    }

    location /_postadmin/ {
        allow 127.0.0.1;
        deny all;
        proxy_pass http://127.0.0.1:20007;
        include proxy_params;
    }

    location / {
        return 301 https://$host$uri;
    }
}

server {
    server_name mail.* smtp.* imap.*;
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    
    keepalive_timeout 70;
    ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
    ssl_ciphers "ECDHE+CHACHA20:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES128-GCM-SHA256:ECDHE+AES256+SHA384:ECDHE+AES256+SHA:EECDH+AESGCM:EDH+AESGCM:AES256+EECDH:AES256+EDH";
    ssl_prefer_server_ciphers on;
    ssl_ecdh_curve secp384r1;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    ssl_dhparam /path/to/dhparams.pem;
    ssl_stapling on;
    ssl_stapling_verify on;
    resolver 106.187.95.5 106.186.116.5 106.186.123.5 106.186.124.5 106.187.90.5 106.187.93.5 106.187.94.5 106.187.34.20 106.187.35.20 106.187.36.20 valid=300s;
    resolver_timeout 5s;
    add_header Strict-Transport-Security "max-age=63072000; preload";
    add_header X-Frame-Options DENY;
    add_header X-Content-Type-Options nosniff;
    ssl_certificate /path/to/mail.pem;
    ssl_certificate_key /path/to/mail.key;

    location /_postadmin/ {
        allow 127.0.0.1;
        deny all;
        proxy_pass http://127.0.0.1:20007;
        include proxy_params;
    }
    
    location / {
        proxy_pass http://127.0.0.1:20007;
        include proxy_params;
    }
}

```

Wish you a secured mail server.
