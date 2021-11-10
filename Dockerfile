ARG DISTRO=alpine
ARG DISTRO_TAG=3.14.2

FROM ${DISTRO}:${DISTRO_TAG}

ARG AS_PDNS_VERSION=4.5.7

ENV PDNS_setuid=${PDNS_setuid:-pdns} \
  PDNS_setgid=${PDNS_setgid:-pdns} \
  PDNS_daemon=${PDNS_daemon:-no} \
  AS_PDNS_VERSION=${AS_PDNS_VERSION}

COPY src/pdns-recursor-${AS_PDNS_VERSION}.tar.bz2 /tmp/

COPY files/* /srv/

RUN apk update \
  && apk add python3 py3-virtualenv py3-pip boost-dev boost-serialization boost-system boost-thread boost-context openssl-dev net-snmp-dev g++ make pkgconfig lua5.3-dev luajit-dev \
  && pip3 install --no-cache-dir envtpl

RUN mv /srv/entrypoint.sh / \
  && cat /tmp/pdns-recursor-${AS_PDNS_VERSION}.tar.bz2 | tar xj -C /tmp \
  && cd /tmp/pdns-recursor-${AS_PDNS_VERSION} \
  && ./configure --prefix="" --exec-prefix=/usr --sysconfdir=/etc/pdns \
  && make \
  && make install \
  && cd / \
  && rm -rf /tmp/pdns-recursor-${AS_PDNS_VERSION} \
  && mkdir -p /etc/pdns/conf.d \
  && mkdir -p /var/run/pdns-recursor \
  && addgroup ${PDNS_setgid} 2>/dev/null \
  && adduser -S -s /bin/false -H -h /tmp -G ${PDNS_setgid} ${PDNS_setuid} 2>/dev/null \
  && chown -R ${PDNS_setuid}:${PDNS_setgid} /etc/pdns/conf.d /var/run/pdns-recursor

EXPOSE 53/tcp 53/udp 8082/tcp

ENTRYPOINT ["sh", "/entrypoint.sh"]

CMD ["/usr/sbin/pdns_recursor"]
