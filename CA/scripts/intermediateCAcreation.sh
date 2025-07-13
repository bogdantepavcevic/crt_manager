#! /bin/bash

current_dir=$(pwd)

echo "Enter the path to directory where all Intermediate CA information will be stored. This is directoy"
echo  "for intermediate CA, where will hold all certificates (clients, servers...), certificate revocation list (CRLs), private keys,"
read -p "tracks of issued certificates, OpenSSL configuration file. [ /root/intermediate ]: " dir

if [ ! -n "$dir" ]
then
        mkdir "$HOME"/intermediate
        dir="$HOME"/intermediate
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

echo -e "\nEnter the path to OpenSSL configuration file for the Intermediate CA. This file defines"
echo "the structure and extensions of the certificates being created and is used when"
echo "generating new certificates and certificate signing requests (csr). You can use"
echo "the provided file in the root directory of crt_manager tool on the GitHub"
read -p "(openssl.cnf, this is adopt for the Intermediate CA) or specify path for new file: " opn
if [ ! -n "$opn" ]
then
        cp "$current_dir"/../config/openssl.cnf "$dir"/
        cnf="$dir"/openssl.cnf
	# Edit default directory in openssl.cnf file
	sed -i "s~^dir\s*=\s\/.*~dir               = ${cahome}~" $opn 

else
        cnf=$opn
	# Edit default directory in openssl.cnf file
	sed -i "s~^dir\s*=\s\/.*~dir               = ${cahome}~" $opn 

fi


while true; do
        read -p "Do you want to edit openssl.cnf file (you can also edit this file manually in intermediate CA directory)? [Y/N] " p
        case "$p" in
                Y|y )
                        # Open openssl.cnf for edit
                        nano "$dir"/openssl-rootCA.cnf
                        break
                        ;;
                N|n )
                        break
                        ;;
                * )
                        echo -e "\e[31mERROR\e[0m: Invalid symbol!"
                        ;;
        esac
done


echo "Next step is creation of intermediate private key and that need to be signed by Root CA. It is recommended that"
echo "intermediate certificate has long expiry date, for example 10 years. Intermediate certificate is used for signing"
echo "all others certificates (client, server...)."
read -p "Enter the name of the intermediate private key [ ca.key.pem ]: " pk
read -p "Enter the name of the intermediate certificate [ ca.cert.pem ]: " cert
read -p "Enter the duration period [ in days, 3600 is 10 years ] " t
read -p "Enter the path to root private key, that will be used by signing certificate for intermediate CA: " rootKEY

if [ -n "$pk" ]
then
        if [  -n "$cert" ]
        then
                if [  -n "$t" ]
                then
                        openssl genrsa -out "$dir"/private/"$pk" 4096
                        chmod 400 "$dir"/private/"$pk"
                        openssl req -config "$dir"/openssl.cnf -key "$rootKEY" -new -x509 -days $t -sha256 -extensions v3_ca -out "$dir"/certs/"$cert"
                        echo "Intermediate private key and certificate are created."
                        chmod 444 "$dir"/certs/"$cert"
                fi
        fi
fi

echo -e "\e[32mGREAT\e[0m: Intermediate CA is created and now you can signing all certificates!"
