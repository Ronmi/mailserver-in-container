require ["vnd.dovecot.pipe", "copy", "imapsieve", "environment", "variables"];

if environment :matches "imap.user" "*" {
  set "username" "${1}";
}

pipe :copy "/usr/bin/spamc" [ "-d", "spamassassin", "-p", "9000", "-L", "spam", "-u", "${username}" ];
