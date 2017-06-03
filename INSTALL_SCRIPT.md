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
# *MUST* enter data/cert before linking
$ cd data/cert
$ ln -s live/mail/fullchain.pem mail.pem
$ ln -s live/mail/privkey.pem mail.key
```

Certbot will periodically renewal your certification via cron.

## Running install script

PostfixAdmin needs your password to be:

* Minimum length is 5.
* At least 3 characters.
* At least 2 digits.

You have to manually edit the `data/config.inc.php` to loosen/tighten these restrictions before running install script.

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

I'd like to limit access to admin panels from only trusted IP. Here's the configuration:

```nginx
server {
    server_name mail.* smtp.* imap.*;
    listen 80;

	# this is for Certbot
    location /.well-known/ {
        proxy_pass http://127.0.0.1:20007;
        include proxy_params;
    }

    location /_postadmin/ {
        # allow accessing from 127.0.0.1
        allow 127.0.0.1;
        deny all;

        proxy_pass http://127.0.0.1:20007;
        include proxy_params;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }

    location / {
        # complex setting for RainLoop
        # 1. no limit for trusted ip
        # 2. return 404 for admin panel
        # 3. redirect other requests to HTTPS
        set $disallow 0;
        set $redir 1;
        if ($request ~* admin) {
            set $disallow 1;
        }
        # trust 127.0.0.1
        if ($remote_addr = "127.0.0.1")
            set $disallow 0;
            set $redir 0;
        }
        if ($redir) {
            return 301 https://$host$uri;
        }
        if ($disallow) {
            return 404;
        }

        proxy_pass http://127.0.0.1:20007;
        include proxy_params;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}

server {
    server_name mail.* smtp.* imap.*;
    include ssl_params;
    ssl_certificate /home/ronmi/docker/mail/data/cert/mail.pem;
    ssl_certificate_key /home/ronmi/docker/mail/data/cert/mail.key;

    location /_postadmin/ {
        # allow accessing from 127.0.0.1
        allow 127.0.0.1;
        deny all;

        proxy_pass http://127.0.0.1:20007;
        include proxy_params;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
    
    location / {
        # complex setting for RainLoop
        # 1. no limit for trusted ip
        # 2. return 404 for admin panel
        set $disallow 0;
        if ($request ~* admin) {
            set $disallow 1;
        }
        # trust 127.0.0.1
        if ($remote_addr = "127.0.0.1")
            set $disallow 0;
        }
        if ($disallow) {
            return 404;
        }

        proxy_pass http://127.0.0.1:20007;
        include proxy_params;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
```

Wish you a secured mail server.
