#!/bin/bash

echo 'postfix	postfix/main_mailer_type	select	No configuration' | debconf-set-selections
dpkg-reconfigure postfix
