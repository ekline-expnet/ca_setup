## Helper Scripts

This repository contains a couple of helper scripts.

| Script | Description |
| :--- | :--- |
| setup_ca.sh   | Create a working certificate authority  |
| create_cert.sh   | Create a certificate using the CA  |

### setup_ca.sh

This script sets up a certificate authority certificate,
an intermediate ca certificate, and a ca-chain file
along with a folder structure and openssl.cnf files for
both the ca and intermediate signing requests.

To define where the CA folder structure is written, update
the file [defaults.txt](defaults.txt).

The templates used for the openssl.cnf are in this directory too:

| Used with | File |
| :--- | :--- |
|  CA Cert  | [ca_openssl.template.cnf](ca_openssl.template.cnf)  |
|  Intermediate Cert  | [intermediate_openssl.template.cnf](intermediate_openssl.template.cnf)  |

The folder structure created is:

```
/ca
  /root
    /certs
    /crl
    /intermediate
      /certs
      /crl
      /csr
      /newcerts
      /private
    /newcerts
    /private

```

| Folder | What is stored in folder |
| :--- | :--- |
| certs   | certificates created  |
| crl   | certificate revocation lists  |
| csr   | certificate signing requests  |
| private   | private keys created |
## CA Setup for MongoDB and Mongo BI Connector

1.  Create Certificate Authority

  * [How to set up a Certificate Authority](https://jamielinux.com/docs/openssl-certificate-authority/index.html)
  * Create CA, Intermediate pairs
  * A single CA SHOULD issue both sever and client certificates
  * client and member (cluster member) certificates MUST have different O, OU, and DC combinations; if O, OU, and DC are the same on a client certificate as on a Member certificate, the client will be treated as a member of the cluster and given full permissions on the system.


2. Create server certificate for MongoDB

  * Subject MUST be FQDN of server (e.g. db.j.expr.net)
  * Subject CAN NOT be an IP Address

3. Create client certificates

  * User a different O or OU for the subject than used for servers or member certificates
  * Avoid special characters that will cause encoding issues when logging into the server


4. Create $external account in MongoDB
5. Configure MongoDB
6. Configure Mongo BI Connector
