#!/bin/bash

# Setup mail
if [[ -n "$MAIL_HOST" ]]; then
  cat <<EOF > /etc/msmtprc
account default
keepbcc on
auth on
tls on
tls_starttls off
tls_certcheck on
host ${MAIL_HOST}
port ${MAIL_PORT}
user ${MAIL_USER}
from ${MAIL_USER}
password ${MAIL_PASSWORD}
EOF
  chmod 600 /etc/msmtprc
  chown nobody /etc/msmtprc
fi

/usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf