FROM alpine:edge

RUN apk --no-cache add ca-certificates=20191127-r5 bash=5.1.4-r0 curl=7.75.0-r0 ip6tables=1.8.7-r0 iproute2=5.11.0-r0 openssl=1.1.1j-r0 strongswan=5.9.1-r0
EXPOSE 500/udp \
       4500/udp

ENTRYPOINT ["/usr/sbin/ipsec"]
CMD ["start", "--nofork"]

