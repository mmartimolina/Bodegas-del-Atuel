#!/bin/sh
set -eu

: "${FRONTEND_API_BASE_URL:=http://localhost:8000}"
envsubst '${FRONTEND_API_BASE_URL}' \
  < /usr/share/nginx/html/config.js.template \
  > /usr/share/nginx/html/config.js
exec nginx -g 'daemon off;'
