#! /bin/bash

current_dir=$(pwd)

echo "Enter the path to directory where all Intermediate CA information will be stored. This is directoy"
echo  "for intermediate CA, where will hold all certificates, certificate revocation list (CRLs), private keys,"
read -p "tracks of issued certificates, OpenSSL configuration file. [ /root/intermediate ]: " dir

if [ ! -n "$dir" ]
then
        mkdir "$HOME"/ca
        dir="$HOME"/ca
else
        t=$(dirname "$dir")
        if [ -e "$t" ]
        then
                mkdir "$dir"
        else
                echo -e "\e[31mERROR\e[0m: Specified path doesn't exist!"
                exit 13
        fi
fi




#Create root CA, prepare the directory and database for storing certificates

mkdir "$dir"/certs "$dir"/crl "$dir"/csr "$dir"/newcerts "$dir"/private
chmod 700 "$dir"/private
touch "$dir"/index.txt
echo 1000 > "$dir"/serial
echo 1000 > "$dir"/crlnumber


#Configuration of openssl.cnf

read -p "Enter the home directory for CA in openssl.cnf file: " cahome 	#cahome must be same as dir
read -p "Enter the path to openssl configuration file: " opn
sed -i "s~^dir\s*=\s\/.*~dir               = ${cahome}~" $opn 
