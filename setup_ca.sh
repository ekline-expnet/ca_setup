#!/usr/bin/env bash
set -e
source ./defaults.txt
source ./ca_functions.sh


# if [ -d "$CA_ROOT" ]; then
#   rm -rf $CA_ROOT
# fi
#Prepare Directory
mkdir -p $CA_ROOT
cd $CA_ROOT
mkdir certs crl newcerts private
chmod 700 private
touch index.txt
echo 1000 > serial

#Prepare config file
cp $CA_OPENSSL_CNF $CA_ROOT/openssl.cnf
sed -i -e "s/__CA_ROOT__/$(sed 's/[&/\]/\\&/g' <<< "$CA_ROOT")/g" $CA_ROOT/openssl.cnf
sed -i -e "s/__DEFAULT_COUNTRY__/$(sed 's/[&/\]/\\&/g' <<< "$DEFAULT_COUNTRY")/g" $CA_ROOT/openssl.cnf
sed -i -e "s/__DEFAULT_O__/$(sed 's/[&/\]/\\&/g' <<< "$DEFAULT_O")/g" $CA_ROOT/openssl.cnf
sed -i -e "s/__DEFAULT_OU__/$(sed 's/[&/\]/\\&/g' <<< "$DEFAULT_OU")/g" $CA_ROOT/openssl.cnf

cd $CA_ROOT

#generate the ca private key
gen_key private/ca.key.pem $CA_SIZE $CA_ENCRYPT
# openssl genrsa -aes256 -out private/ca.key.pem $CA_SIZE
# chmod 400 private/ca.key.pem

cd $CA_ROOT
openssl req -config openssl.cnf \
  -key private/ca.key.pem \
  -new -x509 -days 7300 -sha256 -extensions v3_ca \
  -out certs/ca.cert.pem
  # -subj "$(sed 's/[&\ ]/\\&/g' <<< "$CA_SUBJ")" \
chmod 444 certs/ca.cert.pem
#display ca cert
openssl x509 -noout -text -in certs/ca.cert.pem

#prepare intermediate directory
cd $CA_ROOT
mkdir intermediate
cd $CA_ROOT/intermediate
mkdir certs crl csr newcerts private
chmod 700 private
touch index.txt
echo 1000 > serial
echo 1000 > crlnumber

#prepare intermediate openssl.cnf file
cp $INTER_OPENSSL_CNF $CA_ROOT/intermediate/openssl.servers.cnf
sed -i -e "s/__CA_ROOT__/$(sed 's/[&/\]/\\&/g' <<< "$CA_ROOT")/g" $CA_ROOT/intermediate/openssl.servers.cnf
sed -i -e "s/__DEFAULT_COUNTRY__/$(sed 's/[&/\]/\\&/g' <<< "$DEFAULT_COUNTRY")/g" $CA_ROOT/intermediate/openssl.servers.cnf
sed -i -e "s/__DEFAULT_O__/$(sed 's/[&/\]/\\&/g' <<< "$DEFAULT_O")/g" $CA_ROOT/intermediate/openssl.servers.cnf
sed -i -e "s/__DEFAULT_OU__/$(sed 's/[&/\]/\\&/g' <<< "$DEFAULT_OU")/g" $CA_ROOT/intermediate/openssl.servers.cnf
sed -i -e "s/__DEFAULT_DC__/$(sed 's/[&/\]/\\&/g' <<< "servers")/g" $CA_ROOT/intermediate/openssl.servers.cnf

#hack to clean up file created by sed
if [ -f $CA_ROOT/intermediate/openssl.servers.cnf-e ]; then
  rm -f $CA_ROOT/intermediate/openssl.servers.cnf-e
fi
cp $INTER_OPENSSL_CNF $CA_ROOT/intermediate/openssl.users.cnf

sed -i -e "s/__CA_ROOT__/$(sed 's/[&/\]/\\&/g' <<< "$CA_ROOT")/g" $CA_ROOT/intermediate/openssl.users.cnf
sed -i -e "s/__DEFAULT_COUNTRY__/$(sed 's/[&/\]/\\&/g' <<< "$DEFAULT_COUNTRY")/g" $CA_ROOT/intermediate/openssl.users.cnf
sed -i -e "s/__DEFAULT_O__/$(sed 's/[&/\]/\\&/g' <<< "$DEFAULT_O")/g" $CA_ROOT/intermediate/openssl.users.cnf
sed -i -e "s/__DEFAULT_OU__/$(sed 's/[&/\]/\\&/g' <<< "$DEFAULT_OU")/g" $CA_ROOT/intermediate/openssl.users.cnf
sed -i -e "s/__DEFAULT_DC__/$(sed 's/[&/\]/\\&/g' <<< "users")/g" $CA_ROOT/intermediate/openssl.users.cnf

#hack to clean up file created by sed
if [ -f $CA_ROOT/intermediate/openssl.users.cnf-e ]; then
  rm -f $CA_ROOT/intermediate/openssl.users.cnf-e
fi

#create the intermediate key
cd $CA_ROOT
gen_key $CA_ROOT/intermediate/private/intermediate.key.pem $CA_SIZE $CA_ENCRYPT
# openssl genrsa -aes256 -out intermediate/private/intermediate.key.pem $CA_SIZE
# chmod 400 intermediate/private/intermediate.key.pem

#create the intermediate cert
cd $CA_ROOT

openssl req -config intermediate/openssl.servers.cnf -new -sha256 \
  -key intermediate/private/intermediate.key.pem \
  -out intermediate/csr/intermediate.csr.pem
  # -subj "$(sed 's/[&\ ]/\\&/g' <<< "$INTER_SUBJ")" \
  #
openssl ca -config openssl.cnf -extensions v3_intermediate_ca \
  -days 3650 -notext -md sha256 \
  -in intermediate/csr/intermediate.csr.pem \
  -out intermediate/certs/intermediate.cert.pem

chmod 444 intermediate/certs/intermediate.cert.pem

show_cert intermediate/certs/intermediate.cert.pem

openssl verify -CAfile certs/ca.cert.pem intermediate/certs/intermediate.cert.pem

#create ca-chain
cat intermediate/certs/intermediate.cert.pem \
  certs/ca.cert.pem > intermediate/certs/ca-chain.cert.pem

chmod 444 intermediate/certs/ca-chain.cert.pem
