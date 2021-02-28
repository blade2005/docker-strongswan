#!/bin/sh

C=US
O=StrongSwan
CA_CN=strongswan.org
SERVER_CN=mercury.stoneydavis.com
SERVER_SAN=mercury.stoneydavis.com

CONFIG_DIR=$PWD/config/ipsec.d
IPSEC="docker run -it --rm=true -v $CONFIG_DIR:/etc/ipsec.d strongswan"

mkdir -p "$CONFIG_DIR/aacerts" \
         "$CONFIG_DIR/acerts" \
         "$CONFIG_DIR/cacerts" \
         "$CONFIG_DIR/certs" \
         "$CONFIG_DIR/crls" \
         "$CONFIG_DIR/ocspcerts" \
         "$CONFIG_DIR/private"

eval $IPSEC pki --gen --outform pem > "$CONFIG_DIR/private/caKey.pem"
eval $IPSEC pki --self --in /etc/ipsec.d/private/caKey.pem --dn \"C=$C, O=$O, CN=$CA_CN\" --ca --outform pem > "$CONFIG_DIR/cacerts/caCert.pem"

eval $IPSEC pki --gen --outform pem > "$CONFIG_DIR/private/serverKey.pem"
eval $IPSEC pki --issue --in /etc/ipsec.d/private/serverKey.pem --type priv --cacert /etc/ipsec.d/cacerts/caCert.pem --cakey /etc/ipsec.d/private/caKey.pem --dn \"C=$C, O=$O, CN=$SERVER_CN\" --san=\"$SERVER_SAN\" --flag serverAuth --flag ikeIntermediate --outform pem > "$CONFIG_DIR/certs/serverCert.pem"


client_cns=$(cat client_cn.txt)

if [ -z "$client_cns" ];then echo Missing client names to create.;exit 1;fi

for client_cn in $client_cns;do
  echo "Generating client cert for $client_cn"
  eval $IPSEC pki --gen --outform pem > "$CONFIG_DIR/private/$client_cn.pem"
  eval $IPSEC pki --issue --in "/etc/ipsec.d/private/$client_cn.pem" --type priv --cacert /etc/ipsec.d/cacerts/caCert.pem --cakey /etc/ipsec.d/private/caKey.pem --dn \"C=$C, O=$O, CN=$client_cn\" --san=\"$client_cn\" --outform pem > "$CONFIG_DIR/certs/$client_cn.pem"
  openssl pkcs12 -export -inkey "$CONFIG_DIR/private/$client_cn.pem" -in "$CONFIG_DIR/certs/$client_cn.pem" -name \"$client_cn\" -certfile $CONFIG_DIR/cacerts/caCert.pem -caname \"$CA_CN\" -out "$CONFIG_DIR/$client_cn.p12"
  echo ": RSA $client_cn.pem" >> config/ipsec.secrets
done

sort -n config/ipsec.secrets | uniq > config/ipsec.secrets2
mv config/ipsec.secrets{2,}
