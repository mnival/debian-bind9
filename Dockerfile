FROM debian:stable-20250407-slim

LABEL maintainer="Michael Nival <docker@mn-home.fr>" \
	name="debian-bind9" \
	description="Debian Stable with the package bind9" \
	docker.cmd="docker run -d -p 53:53/udp -p 53:53 -v "$(pwd)/bind.d:/etc/bind/bind.d" -v "$(pwd)/cache:/var/cache/bind" --name bind9 mnival/debian-bind9"

RUN printf "deb http://deb.debian.org/debian/ stable main\ndeb http://deb.debian.org/debian/ stable-updates main\ndeb http://security.debian.org/debian-security stable-security main\n" >> /etc/apt/sources.list.d/stable.list && \
	cat /dev/null > /etc/apt/sources.list && \
	export DEBIAN_FRONTEND=noninteractive && \
	apt update && \
	apt -y --no-install-recommends full-upgrade && \
	addgroup --system --gid 120 bind && \
	adduser --system --home /var/cache/bind --no-create-home --disabled-password --uid 120 --ingroup bind bind && \
	apt install -y --no-install-recommends bind9 && \
	echo "UTC" > /etc/timezone && \
	rm /etc/localtime && \
	dpkg-reconfigure tzdata && \
	rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /var/log/alternatives.log /var/log/dpkg.log /var/log/apt/ /var/cache/debconf/*-old

RUN sed -i 's/\(named.conf.options\|named.conf.local\)/bind.d\/\1/g' /etc/bind/named.conf && \
	mkdir /etc/bind/bind.d && \
	mv /etc/bind/rndc.key /etc/bind/bind.d/ && \
	ln -s /etc/bind/bind.d/rndc.key /etc/bind/rndc.key && \
	rm /etc/bind/bind.d/rndc.key

RUN printf 'include "/etc/bind/bind.d/rndc.key";\ncontrols {\n\tinet 127.0.0.1 port 953 allow { 127.0.0.1; } keys { "rndc-key";};\n};\n' > /etc/bind/named.conf.controls && \
	sed -i 's#^\(.\+named.conf.options.\+\)#\1\ninclude "/etc/bind/named.conf.controls";#g' /etc/bind/named.conf

ADD start-bind9 /usr/local/bin/

HEALTHCHECK CMD rndc status || exit 1

VOLUME ["/var/cache/bind", "/etc/bind/bind.d"]

EXPOSE 53/udp 53/tcp

ENTRYPOINT ["start-bind9"]
