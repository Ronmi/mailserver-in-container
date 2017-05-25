#!/bin/bash

echo '
CREATE DATABASE IF NOT EXISTS mail CHARACTER SET utf8 COLLATE utf8_general_ci;
' | mysql -u root "-p${MYSQL_ROOT_PASSWORD}"
