cert_info() {
    local certFile="$1"
    local certCN certIssuer certValid certExpire certCA certFilename

    if [ -r "$certFile" ]; then
	certFilename=$(basename "$certFile")
        certCN="$(openssl x509 -in "$certFile" -noout -subject | sed -r 's|.*CN=(.*)|\1|; s|/[^/]*=.*$||')"
        certIssuer="$(openssl x509 -in "$certFile" -noout -issuer | sed -r 's|.*CN=(.*)|\1|; s|/[^/]*=.*$||')"
        certValid="$(openssl x509 -in "$certFile" -noout -startdate | sed -r 's|.*notBefore=(.*)|\1|;')"
        certExpire="$(openssl x509 -in "$certFile" -noout -enddate | sed -r 's|.*notAfter=(.*)$|\1|;')"
	if [ "$certCN" = "$certIssuer" ]; then
            echo "$certFilename: $certCN expires on $certExpire"
        else
            echo "$certFilename: $certCN issued by $certIssuer expires on $certExpire"
        fi
    else
        echo "ERROR: $certFile does not exist or cannot be read"
    fi
}

#generate a key w/out a passphrase... add -sha256 to encrypt
gen_key() {
  local size=2048
  if [[ $2 != "" ]]; then
    size=$2
  fi
  encrypt=""
  if [[ $3 != "" ]]; then
    encrypt=" -aes256 "
  fi
  openssl genrsa $encrypt -out $1 $size;
  chmod 400 $1
}

gen_csr() {
  if [[ $# < 3 ]]; then
    echo "Incorrect number of paramters, need at least 3 for gen_csr, received $#";
    exit 1;
  fi
  local subj=""
  if [[ $4 != "" ]]; then
    subj="-subj \""$4"\""
  fi
  echo "$3"
  echo "openssl req -config $1 -key $2 -new -sha256 $subj -out $3"
  openssl req -config $1 -key $2 -new -sha256 $subj -out $3;
}

show_cert() {
  openssl x509 -noout -text -in $1
}

gen_cert() {
  echo "generating cert with no extensions"
  openssl ca -config $1 -days $4 -notext \
    -md sha256 -in $2 -out $3;
  chmod 444 $3;
}

gen_server_cert() {
  if [ $5 = true ]; then
    gen_cert $1 $2 $3 $4 $5
  else
    echo "generating cert with server extension"
    openssl ca -config $1 -extensions server_cert -days $4 -notext \
      -md sha256 -in $2 -out $3;
    chmod 444 $3;
  fi
}

gen_user_cert() {
  if [ $5 = true ]; then
    gen_cert $1 $2 $3 $4 $5
  else
    echo "generating cert with user extension"
    openssl ca -config $1 -extensions usr_cert -days $4 -notext \
      -md sha256 -in $2 -out $3;
    chmod 444 $3;
  fi
}
