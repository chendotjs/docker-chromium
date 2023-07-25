#!/bin/sh

set -e # Exit immediately if a command exits with a non-zero status.
set -u # Treat unset variables as an error.

export HOME=/config
mkdir -p /config/profile
whoami
exec /usr/bin/firefox_wrapper --user-data-dir=/config/profile --force-dark-mode >> /config/log/chromium/output.log 2>> /config/log/chromium/error.log
