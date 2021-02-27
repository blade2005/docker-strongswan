FROM alpine:edge

RUN apk --update add ca-certificates bash curl ip6tables iproute2 openssl strongswan
EXPOSE 500/udp \
       4500/udp

ENTRYPOINT ["/usr/sbin/ipsec"]
CMD ["start", "--nofork"]

