#! /bin/bash


current_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"


echo "Enter the path to directory where all CA information will be stored. This is directoy"
echo  "for root CA, where will hold intermediate certificates, certificate revocation list (CRLs), private key,"
read -p	"tracks of issued certificates, OpenSSL configuration file. [ /root/ca ]: " dir

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

mkdir "$dir/"certs "$dir"/crl "$dir"/newcerts "$dir"/private
chmod 700 "$dir"/private
touch "$dir"/index.txt
echo 1000 > "$dir"/serial

echo -e "\nEnter the path to OpenSSL configuration file for the root CA. This file defines"
echo "the structure and extensions of the certificates being created and is used when"
echo "generating new certificates and certificate signing requests (csr). You can use"
echo "the provided file in the root directory of crt_manager tool on the GitHub"
read -p "(openssl-rootCA.cnf, this is adopt for the Root CA) or specify path for new file: " opn
if [ ! -n "$opn" ]
then
	cp "$current_dir"/../config/openssl-rootCA.cnf "$dir"/
	cnf="$dir"/openssl-rootCA.cnf
	sed -i "s~^dir\s*=\s\/.*~dir               = ${dir}~" $cnf &>/dev/null

	while true; do
        	read -p "Do you want to edit openssl-rootCA.cnf file (you can also edit this file manually in root CA directory)? [Y/N] " p
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

else
	cnf=$opn
fi







echo "Next step is creation of root private key and root self-signed certificate. It is recommended that root certificate has long"
echo "expiry date, for example 20 years. Root certificate is used only for signing intermediate certificates."
read -p "Enter the name of the root private key [ ca.key.pem ]: " pk_IN
read -p "Enter the name of the root certificate [ ca.cert.pem ]: " cert_IN
read -p "Enter the duration period [ in days, 3600 is 10 years ]: " t_IN

# Check private key
if [ -n "$pk_IN" ]
then
	pk=$pk_IN
else
	pk="ca.key.pem"
fi


# Check certificate
if  [ -n "$cert_IN" ]
then
	cert=$cert_IN
else
	cert="ca.cert.pem"
fi

# Check duration period
if [ -n "$t_IN" ]
then
	if [[ $t_IN -gt 0 ]]
	then
		t=$t_IN
	fi
else
	t=3600
fi


openssl genrsa -out "$dir"/private/"$pk" 4096
chmod 400 "$dir"/private/"$pk"
openssl req -config "$dir"/openssl-rootCA.cnf -key "$dir"/private/"$pk" -new -x509 -days $t -sha256 -extensions v3_ca -out "$dir"/certs/"$cert"

if [[ $? -eq 0 ]]
then
	echo -e "\n\e[32mOK\e[0m: Root CA is successfully created!"
fi
chmod 444 "$dir"/certs/"$cert"


while true; do
	read -p "Do you want to create intermediate CA? [Y/N] " opt
	case "$opt" in
		Y|y )
			"$current_dir"/CA/scripts/intermediateCAcreation.sh
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
