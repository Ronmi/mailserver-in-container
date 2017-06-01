#!/bin/bash

exec /usr/bin/spamc -d spamassassin -p 9000 "$@"
