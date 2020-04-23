#!/bin/bash

# Setup mail
if [[ -n "$SMTP_HOST" ]]; then
  cat <<EOF > /etc/msmtprc
account default
keepbcc on
auth on
tls on
tls_starttls off
tls_certcheck on
host ${SMTP_HOST}
port ${SMTP_PORT}
user ${SMTP_USER}
from ${SMTP_FROM}
password ${SMTP_PASS}
EOF
  chmod 600 /etc/msmtprc
  chown nobody /etc/msmtprc
fi