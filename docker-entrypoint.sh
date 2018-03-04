#!/bin/bash
unset IFS
set -eo pipefail
shopt -s nullglob

if [ -e /firstrun ] && [ -z "$OMIT_FIRSTRUN" ]; then
        if [ ! -z "$SELFUPDATE" ]; then
		if [ "$SELFUPDATE" != "2" ]; then
			sed -i 's/apply_updates = no/apply_updates = yes/g' /etc/yum/yum-cron.conf
                	systemctl enable yum-cron
		fi
                yum update -y
        fi

	if [ ! -z "$TZ" ]; then
		TIMEZONE="$TZ"
	fi

        if [ ! -z "$TIMEZONE" ] && [ -e "/usr/share/zoneinfo/$TIMEZONE" ]; then
                ln -sf "/usr/share/zoneinfo/$TIMEZONE" /etc/localtime
        fi

	if [ ! -z "$HAPROXY_INCROND" ]; then
		echo "/etc/haproxy/haproxy.cfg IN_MODIFY,IN_NO_LOOP flock -F -x -w1 -E0 /tmp/.haproxy-reload systemctl reload haproxy" >/etc/incron.d/haproxy
		systemctl enable incrond
	fi

	if [ ! -z "$HAPROXY_LETSENCRYPT_INCROND" ]; then
		echo "/etc/letsencrypt/live/*/fullkeychain.pem IN_MODIFY,IN_NO_LOOP flock -F -x -w1 -E0 /tmp/.haproxy-reload systemctl reload haproxy" >/etc/incron.d/letsencrypt
		systemctl enable incrond
	fi

	if [ ! -z "$HAPROXY_LETSENCRYPT" ]; then
		domains=()
		for var in $(compgen -e); do
		        if [[ "$var" =~ LETSENCRYPT_DOMAIN_.* ]]; then
        		        domains+=( "${!var}" )
		        fi
		done
		for entry in "${domains[@]}"; do
        		array=(${entry//,/ })
        		/usr/local/sbin/certbot-issue ${array[@]}
		done
        fi	
fi

rm -f /firstrun

exec "$@"
