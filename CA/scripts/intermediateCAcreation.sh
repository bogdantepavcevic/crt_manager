
#! /bin/bash

current_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "\nEnter the path to directory where all Intermediate CA information will be stored. This is directoy for intermediate CA,"
echo  "where will hold all certificates (clients, servers...), certificate revocation list (CRLs), private keys,"
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




#Create intermediate CA, prepare the directory and database for storing certificates

mkdir "$dir"/certs "$dir"/crl "$dir"/csr "$dir"/newcerts "$dir"/private
chmod 700 "$dir"/private
touch "$dir"/index.txt
echo 1000 > "$dir"/serial
echo 1000 > "$dir"/crlnumber


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
	sed -i "s~^dir\s*=\s\/.*~dir               = ${dir}~" $cnf &>/dev/null

	while true; do
        	read -p "Do you want to edit openssl.cnf file (you can also edit this file manually in intermediate CA directory)? [Y/N] " p
        	case "$p" in
        	        Y|y )
                	        # Open openssl.cnf for edit
                        	nano "$dir"/openssl.cnf
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

else
        cnf=$opn
fi


echo "Next step is creation of intermediate private key and that need to be signed by Root CA. It is recommended that"
echo "intermediate certificate has long expiry date, for example 10 years. Intermediate certificate is used for signing"
echo "all others certificates (client, server...)."
read -p "Enter the name of the intermediate private key [ intermediate.key.pem ]: " pk_IN
read -p "Enter the name of the intermediate certificate [ intermediate.cert.pem ]: " cert_IN
echo "Enter the duration period (NOTE: Duration of Intermediate certificate can't exceeed duration"
read -p "of Root certificate):  [ in days, 3600 is 10 years ] " t_IN
read -p  "Enter the path to root private key, that will be used by signing certificate for intermediate CA: " rootKEY


# Check private key
if [ -n "$pk_IN" ]
then
	pk=$pk_IN
else
        pk="intermediate.key.pem"
fi


# Check certificate
if [  -n "$cert_IN" ]
then
        cert=$cert_IN
else
        cert="intermediate.cert.pem"
fi

if [  -n "$t_IN" ]
then
        if [[ $t_IN -gt 0 ]]
        then
                t=$t_IN
        fi
else
        t=3600

fi

if [ -f "$rootKEY" ]
then
	openssl genrsa -out "$dir"/private/"$pk" 4096
	chmod 400 "$dir"/private/"$pk"
	openssl req -config "$dir"/openssl.cnf -key "$rootKEY" -new -x509 -days $t -sha256 -extensions v3_ca -out "$dir"/certs/"$cert"
	chmod 444 "$dir"/certs/"$cert"
	if [[ $? -eq 0 ]]
	then
		echo -e "\e[32mOK\e[0m: Intermediate CA is created and now you can signing users and servers certificates!"
	fi
else
	echo -e "\e[31mERROR\e[0m: Root key doesn't exist on specified path."
fi

