#! /bin/bash
# Copyright (C) 2017 Joshua Watt
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

# strict mode
set -euo pipefail

DUPLICITY=$(which duplicity)
MSMTP=$(which msmtp)
FORCE_FAIL=false
PROFILE="$HOME/.simple-duplicity.conf"

send_email() {
    local SUBJECT="$1"
    $MSMTP $MSMTP_ARGS <<HEREDOC
Subject: $SUBJECT
$($HTML_EMAIL && cat <<EOF
MIME-Version: 1.0
Content-Type: text/html
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html>
<head><title></title></head>
<body><pre>
EOF
)
$(cat $LOG_FILE)
$($HTML_EMAIL && cat <<EOF
</pre></body></html>
EOF
)
HEREDOC
}

on_exit() {
    EXIT_CODE=$?
    unset PASSPHRASE
    if [ $EXIT_CODE -eq 0 ]; then
        if [ -n "$SUCCESS_SUBJECT" ]; then
            send_email "$SUCCESS_SUBJECT"
        fi
    else
        if [ -n "$FAILURE_SUBJECT" ]; then
            send_email "$FAILURE_SUBJECT"
        fi
    fi
    rm -f "$LOG_FILE"
}

print_help() {
    echo "Usage:"
    echo "$(basename $0) [-h] [--fail] [--profile PROFILE] -- [duplicity options]"
    echo "  -h --help           Show help"
    echo "  --fail              Force a failure for testing"
    echo "  --profile PROFILE   Load PROFILE for configuration (defaults to $PROFILE)"
}
ARGS=$(getopt -o h --long fail,profile:,help -n "$(basename $0)" -- "$@")

eval set -- $ARGS

while [ -n "$1" ]; do
    a="$1"
    shift
    case "$a" in
        -h|--help)
            print_help
            exit 0
            ;;
        --fail)
            FORCE_FAIL=true
            ;;
        --profile)
            PROFILE="$1"
            shift
            ;;
        --)
            break
            ;;
        *)
            echo "Unknown option '$a'"
            exit 1
            ;;
    esac
done

if [ -z "$PROFILE" ]; then
    echo "Profile required"
    exit 1
fi

source $PROFILE

trap on_exit EXIT

DUPLICITY_ARGS="$DUPLICITY_ARGS $@"
export PASSPHRASE
export SIGN_PASSPHRASE

LOG_FILE=$(mktemp)

$DUPLICITY \
    $DUPLICITY_ARGS \
    $DUPLICITY_BACKUP_ARGS \
    --full-if-older-than $FULL_INTERVAL \
    "$BACKUP_SOURCE" $BACKUP_TARGET | tee -a $LOG_FILE

if [ -n "$DUPLICITY_REMOVE_OLD_ARGS" ]; then
    echo "" | tee -a $LOG_FILE
    $DUPLICITY $DUPLICITY_REMOVE_OLD_ARGS $DUPLICITY_ARGS --force $BACKUP_TARGET | tee -a $LOG_FILE
fi

echo "" | tee -a $LOG_FILE
$DUPLICITY cleanup $DUPLICITY_ARGS --force $BACKUP_TARGET | tee -a $LOG_FILE

echo "" | tee -a $LOG_FILE
$DUPLICITY collection-status $DUPLICITY_ARGS $BACKUP_TARGET | tee -a $LOG_FILE

if $FORCE_FAIL; then
    echo "Forcing Failure..." | tee -a $LOG_FILE
    false
fi

