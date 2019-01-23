#!/usr/bin/env bash
set -e
  #statements
source ./defaults.txt
source ./ca_functions.sh

usage() {
  cat <<__EOT__
Usage: $0 [options]

Options:
  -h, --help                  Print this helpful message
  -d, --days DAYS             Number of days cert is valid
  -s, --server                Create server cert
  -u, --User                  Create user cert
  -b, --basename BASENAME     Basename for cert/key pair to be save in $CA_ROOT/intermeidate (required)
}

__EOT__
}

# if [ "$#" == "0" ]; then
# 	usage; exit 0;
# fi

CA_DAYS=365
CERT_TYPE="server"
basename=""
subject=""
skip_encrypt=FALSE
no_extension=FALSE
while [ "$1" != "" ]; do
  case "$1" in
    -h|--help) usage; exit 0;;
    -d|--days) shift; CA_DAYS="$1"; shift;;
    -s|--server) CERT_TYPE="server"; shift;;
    -u|--user) CERT_TYPE="user"; shift;;
    -b|--basename) shift; basename="$1"; shift;;
    --no-extension) shift; no_extension=TRUE;;
    --unencrypted) shift; skip_encrypt=TRUE;;
    # --subject) shift; subject="$1"; shift;;
    --) shift; break;;
    *) echo "Unknown value '$1'"; exit 1;;
  esac
done

if [[ $basename == "" ]]; then
  usage; exit 0;
fi;
cd $CA_ROOT
cnf="$CA_ROOT/intermediate/openssl.servers.cnf"
encrypt=""

if [[ $CERT_TYPE != "server" ]]; then
  cnf=$CA_ROOT/intermediate/openssl.users.cnf
  encrypt="aes256"
fi

if [[ $skip_encrypt ]]; then
  encrypt=""
fi

gen_key $CA_ROOT/intermediate/private/$basename.key.pem 2048 $encrypt
csr=$CA_ROOT"/intermediate/csr/"$basename".csr.pem"
key=$CA_ROOT"/intermediate/private/"$basename".key.pem"

gen_csr "$cnf" "$key" "$csr";

if [[ $CERT_TYPE == "server" ]]; then
  gen_server_cert $cnf \
    $CA_ROOT/intermediate/csr/$basename.csr.pem \
    $CA_ROOT/intermediate/certs/$basename.cert.pem $CA_DAYS no_extension;
elif [[ $CERT_TYPE == "user" ]]; then
  gen_user_cert $cnf \
    $CA_ROOT/intermediate/csr/$basename.csr.pem \
    $CA_ROOT/intermediate/certs/$basename.cert.pem $CA_DAYS no_extension;
else
  gen_cert $cnf \
    $CA_ROOT/intermediate/csr/$basename.csr.pem \
    $CA_ROOT/intermediate/certs/$basename.cert.pem $CA_DAYS;
fi
show_cert intermediate/certs/intermediate.cert.pem

openssl verify -CAfile \
  $CA_ROOT/intermediate/certs/ca-chain.cert.pem \
  $CA_ROOT/intermediate/certs/$basename.cert.pem;

echo "combining key and cert for mongo"
cat $CA_ROOT/intermediate/private/$basename.key.pem \
  $CA_ROOT/intermediate/certs/$basename.cert.pem \
  > $CA_ROOT/intermediate/certs/$basename.pem
