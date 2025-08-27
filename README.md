# 🔐 crt_manager
![SSL](https://img.shields.io/badge/SSL-Enabled-green)
![TLS](https://img.shields.io/badge/TLS-Supported-blue)
![X509](https://img.shields.io/badge/X.509-Certs-orange)
![Shell](https://img.shields.io/badge/Shell-Bash-blue)

## Description
A Bash-based SSL/TLS management toolkit that streamlines the entire certificate lifecycle. It enables you to create Root and Intermediate Certificate Authorities (CAs), generate private keys and CSRs, issue and revoke certificates, verify and validate PKI components across formats (PEM, DER, PFX), convert certificate formats for compatibility, fetch certificates from remote servers, and monitor expiry dates to prevent outages — all from a lightweight, command-line solution ideal for DevOps, SysAdmins, and security-conscious environments.

## Features

### Certificate Authority Management
- **Create Root or Intermediate CA** – Initialize your own Root Certificate Authority and add an intermediate CA for secure chaining

###  Certificate Lifecycle
- **Generate Private Key** – Create RSA or ECC private keys
- **Generate CSR** – Create Certificate Signing Requests
- **Issue Certificate** – Sign certificates using your CA
- **Revoke Certificate** – Invalidate compromised or expired certificates

### Validation & Verification
- **Verify CSR, Private Key, and Certificate** – Ensure validity across PEM, PFX, and DER formats
- **Check Private Key and Certificate Match** – Confirm key-certificate pairing
- **Convert Certificate Formats** – Convert between PEM, DER, and PFX

###  Monitoring & Fetching
- **Fetch Certificate from Resource** – Pull a certificate from a remote server
- **Check Certificate Expiry** – Validate if certificates in a list are about to expire




## Installation
```bash
# Clone repo
git clone https://github.com/bogdantepavcevic/crt_manager.git

# Enter directory
cd crt_manager

# Add executable permition
chmod +x crt_manager.sh
```

## Requirement
- openssl 
- Run as root (only for CA creation)


## Project Stucture
```
crt_manager/
├── CA/
│ ├── config/
│ │ ├── openssl-rootCA.cnf
│ │ └── openssl.cnf
│ └── scripts/
│ ├── intermediateCAcreation.sh
│ └── rootCAcreation.sh
├── LICENSE
├── README.md
├── cacreation.sh
├── certsList.txt
├── crt_manager.sh
└── isExpire.sh 
```
## Documentation
**Still in progress...**

## Documentation
**Still in progress...**
