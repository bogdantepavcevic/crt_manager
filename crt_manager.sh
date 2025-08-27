#! /bin/bash


##########################################
# Help				         #
##########################################
Help()
{
echo -e "\n"
figlet -f big CRT MANAGER
cat << EOF

This is bash toolkit for managing SSL/TLS certificates. It is designed for cybersecurity engineers,
system administrators, DevOps teams, and anyone managing certificate infrastructure or PKI operations.

USAGE:
	./crt_manager.sh [options]

OPTIONS:
	-h				Help
	-p				Generate the private key
	-C				Generate csr
	-c				Issue a certificate (signing of csr)
	-v				Verify csr, private key, pem, pfx or der certificate
	-x				Change format of the certificate
	-r				Revoke certificate
	-F				Fetch certificate
	-m				Check the private key and certificate match
	-P				Extract public key from certificate
	-L				Get CRL (Certificate Revocation List) list for specified certificate


EXAMPLES:
	./crt_manager.sh -r certificateExample.crt
		Enter the path to the certificate that you want to revoke, only if your certificate was issued by your CA server.

	./crt_manager.sh -F example.com:443"
		Specify the target in format host:port to fetch the SSL/TLS certificate from a remote host.

EOF

}

generate_PK()
{
	read -p "Enter the destination path for storing the private key: " pk
	if [ -n "$pk" ]
	then
		while [[ 1 ]]
		do
			read -p "Enter the size of the private key [2048, 4096]: " bit
        		if [[ $bit -eq 2048 || $bit -eq 4096 ]]
			then
				openssl genrsa -out $pk $bit 2>/dev/null
				break
			else
				echo -e "\e[31mERROR:\e[0m Private key must be 2048 or 4096 bits!"
				exit 22
			fi
		done
	else
		echo -e "\e[31mERROR\e[0m: The name of private key can't be empty string!"
		exit 21
	fi
}

generate_CSR()
{
	#Edit openssl.cnf file
	echo "Provide the path to the openssl configuration file (openssl.cnf)"
	echo "only if you have CA server previously created. If you don't"
	read -p "specify path default openssl config file will be used: " conf
	if [ ! -n $conf ]
        then
		read -p "Provide the path to the to private key: " pk
        	if test -f "$pk"
		then
			read -p "Enter the destination path for storing the csr : " csr
			if [ -n "$csr" ]
			then
				openssl req -config $conf -new -sha256 -key $pk -out $csr
			else
		                echo -e "\e[31mERROR\e[0m: The name of csr can't be empty string!"
                		exit 33
			fi
		else
			echo -e "\e[31mERROR:\e[0m Private key doesn't exist on specified path!"
			exit  32
		fi
	else
		read -p "Provide the path to the to private key: " pk
                if test -f "$pk"
                then
                        read -p "Enter the destination path for storing the csr : " csr
                        if [ -n "$csr" ]
                        then
                                openssl req -new -sha256 -key $pk -out $csr
                        else
                                echo -e "\e[31mERROR\e[0m: The name of csr can't be empty string!"
                                exit 33
                        fi
                else
                        echo -e "\e[31mERROR:\e[0m Private key doesn't exist on specified path!"
                        exit  32
                fi
	fi
}

create_cert()
{
	#Check if exist intermediate private key on the path in openssl.cnf
        read -p "Provide the path to the openssl configuration file (openssl.cnf): " conf
        if test -f $conf
	then
		read -p "Extension in openssl.cnf file (server_cert/usr_cert): " ext
		if [[ $ext='server_cert' ]] || [[ $ext='usr_cert' ]]
        	then
			read -p "Certificate validity preriod, in days (365, 7300...): " t
        		if [[ $t -gt 0 ]]
			then
				read -p "Provide the path to the to the csr: " csr
        			if test -f $csr
				then
					read -p "Enter the destination path for storing the certificate: " crt
        				openssl ca -config $conf -extensions $ext -days $t -notext -md sha256 -in $csr -out $crt 
				else
					echo -e "\e[31mERROR:\e[0m Csr doesn't exist on specified path!"
					exit 44
				fi
			else
				echo -e "\e[31mERROR:\e[0m Certificate validity period must be positive number!"
				exit 43
			fi
		else
			echo -e "\e[31mERROR:\e[0m Extension doesn't exist or currently not supported!"
			exit 42
		fi
	else
		echo -e "\e[31mERROR:\e[0m Configuration file doesn't exist on specified path!"
		exit 41
	fi
}

verify()
{
	echo -e "\nVerify by selecting one of the following options in  brackets:"
	echo -e " (s)   csr \n (c)   certificate \n (p)   private key \n (f)   pfx certificate \n (d) DER certificate"
	read -p "Select option: " opt
	case $opt in
		s)	# Verify csr
			read -p "Provide the path to the csr: " csr
			if test -f $csr
			then
				openssl req -text -noout -verify -in $csr
			else
				echo -e "\e[31mERROR:\e[0m Csr doesn't exist on specified path!"
				exit 52
			fi
			;;
		c)	# Verify certificate
			read -p "Provide the path to the certificate: " crt
			if test -f $crt
			then
				openssl x509 -text -noout -in $crt
			else
				echo -e "\e[31mERROR:\e[0m Certificate doesn't exist on specified path!"
				exit 53
			fi
			;;
		p)	# Verify private key 
			read -p "Provide the path to the private key: " pk
			if test -f $pk 
			then
				openssl rsa -check -in $pk
			else
				echo -e "\e[31mERROR:\e[0m Private key doesn't exist on specified path!"
				exit 54
			fi
			;;
		f)	# Verify pfx certificate
			read -p "Provide the path to the pfx (PKCS12) certificate: " pfx
			if test -f $pfx
			then
				openssl pkcs12 -info -in $pfx
			else
				echo -e "\e[31mERROR:\e[0m Pfx certificate doesn't exist on specified path!"
				exit 55
			fi
			;;
		d)	# Verify der certificate
			read -p "Provide the path to the DER certificates: " der
			if test -f "$der"
			then
				openssl x509 -inform der -in "$der" -text -noout
			else
				echo -e "\e[31mERROR:\e[0m Certificate doesn't exist on specified path!"
				exit 56
			fi
			;;
		\?)	# Nevalidna opcija
			echo -e "\e[31mERROR:\e[0m Invalide option"
			exit 51
			;;
	esac
}

convert()
{
	echo -e "\nEnter the option for convert the certificate:"
	echo -e "  DER			-> 	PEM		(1)"
	echo -e "  PEM			-> 	DER		(2)"
	echo -e "  PKCS#12 (.pfx) 	->	PEM		(3)"
	echo -e "  PEM			-> 	PKCS#12 (.pfx)	(4)"
	read -p "Enter number: " num
#	while [[ 1 ]]
#	do
#		if [[ $num>=1 ]] && [[ $num<=4 ]]
#		then
#			break
#		else
#			echo -e "\e[31mERROR:\e[0m Invalide number"
#			exit 61
#		fi
#	done
	case $num in
		1)	# DER -> PEM
			read -p "Provide the path to the certificate in DER format: " cert
			if test -f $cert
			then
				if [[ $cert==*.der ]]
				then
					echo $cert>/tmp/tmp.txt
					sed -E -i "s/der$/pem/" /tmp/tmp.txt
					TMP=$(cat /tmp/tmp.txt)
					openssl x509 -inform DER -in $cert -out $TMP
					rm /tmp/tmp.txt
				else
					echo -e "\e[31mERROR:\e[0m Certificate must have DER extension!"
					exit 73
				fi
			else
				echo -e "\e[31mERROR:\e[0m Certificate doesn't exist on specified path!"
				exit 72
			fi
			;;
		2)	# PEM -> DER
			read -p "Provide the path to the certificate in PEM format: " cert
			if test -f $cert
			then
				cert_der=$cert'.der'
				openssl x509 -outform DER -in $cert -out $cert_der
			else
				echo -e "\e[31mERROR:\e[0m Certificate doesn't exist on specified path!"
				exit 74
			fi
			;;
		3)	# PFX -> PEM
			read -p "Provide the path to the certificate in PFX format: " cert
			if test -f "$cert"
			then
				openssl pkcs12 -in "$cert" -out "$cert.pem" -nodes
			else
				echo -e "\e[31mERROR\e[0m: Certificate doesn't exist on specified path!"
			fi
			;;
		4)	# PEM -> PFX
			read -p "Provide the path to the certificate in PEM format: " cert
			if test -f "$cert"
			then
				read -p "Provide path to the coresponding private key: " pk
				if test -f "$pk"
				then
					if [[ $(openssl pkey -in $pk -noout | openssl md5)==$(openssl x509 -noout  -in $cert | openssl md5) ]]
					then
						openssl pkcs12 -export -out "$cert.pfx" -inkey "$pk" -in "$cert"
					else
						echo -e "\e[31mERROR\e[0m: Private key and certificate don't match!"
						exit 77
					fi
				else
					echo -e "\e[31mERROR\e[0m: Private key doesn't exist on specified path!"
					exit 75
				fi
			else
				echo -e "\e[31mERROR\e[0m: Certificate doesn't exist on specified path!"
				exit 76
			fi
			;;
		\?)	# Invalid option
			echo -e "\e[31mERROR:\e[0m Invalid option!"
			exit 71
	esac
}

#check if arg empty
revoke()
{
	read -p "Provide the path to openssl.cnf configuration file: " opn
	if test -f "$opn"
	then
		if test -f $OPTARG
		then
			openssl ca -config "$opn" -revoke $OPTARG 
		else
			echo -e "\e[31mERROR\e[0m: Certificate doesn't exist on specified path!"
			exit 81
		fi
	else
		echo -e "\e[31mERROR\e[0m: Configuration file doesn't exist on specified path!"
		exit 82
	fi
}

fetch()
{
	read -p "Enter the path and file name  where certificate will be stored: " cert
	if [ ! -n "$cert" ]
	then
		c="$(pwd)"/"$(echo "$OPTARG" | cut -f 1 -d ":").pem"
		openssl s_client -showcerts -connect $OPTARG 2>/dev/null </dev/null | openssl x509 -text | sed -ne '/BEGIN\ CERTIFICATE/,/END\ CERTIFICATE/p' > $c
	else
		openssl s_client -showcerts -connect $OPTARG 2>/dev/null 1>$cert </dev/null
              	cat "$cert" | openssl x509 -text | sed -ne '/BEGIN\ CERTIFICATE/,/END\ CERTIFICATE/p' > $cert
	fi
}

match()
{
	read -p "Provide the path to the private key: " pk
	if test -f $pk
	then
		read -p "Provide the path to the certificate: " crt
		if test -f $crt
		then
			p=$(openssl pkey -in $pk -noout | openssl md5)
			c=$(openssl x509 -noout  -in $crt | openssl md5)
			if [[ $p==$c ]]
			then
				echo -e "\e[32mOK:\e[0m Certificate and private key match!"
			else
				echo -e "\e[31mNOT OK:\e[0m Certificate and private key don't match!"
			fi
		else
			 	echo -e "\e[31mERROR:\e[0m Certificate and private key don't match!"
			exit 92
		fi
	else
		 echo -e "\e[31mERROR\e[0m: Private key doesn't exist on specified path!"
		exit 91
	fi
}

extract_pub()
{
	read -p "Provide the path to the certificate: " cert
	if test -f $pfx
	then
		read -p "Specify the path where you like to store Public key: " path
		if test -d $(dirname "$dir")
		then
			openssl x509 -in "$cert" -pubkey -noout > "$cert.pub.key"
		else
			echo -e "\e[31mERROR\e[0m: Specified path doesn't exist!"
		fi
	else
		echo -e "\e[31mERROR:\e[0m Pfx certificate doesn't exist on specified path!"
		exit 101
	fi

}

get_crl()
{
	if test -f $OPTARG
	then
		openssl s_client -showcerts -verify 5 -connect "$OPTARG":443 < /dev/null | awk '/BEGIN CERTIFICATE/,/END CERTIFICATE/{ if(/BEGIN CERTIFICATE/){a++}; if(a<=5) print}' > chain-"$OPTARG".pem 
		t=$(openssl x509 -in $OPTARG -text -noout | grep "CRL Distribution" -A 5 | grep URI | cut -f 2,3 -d ":")
		wget $t
		openssl crl -inform DER -in $t -outform PEM -out $t.pem
		cat chain-"$OPTARG".pem $t > chain-crl.pem
		openssl verify -crl_check -CAfile $t chain-"$OPTARG".pem
	else
		echo -e "\e[31mERROR\e[0m: Certificate doesn't exist on specified path!"
		exit 111
	fi

}

#########################################
# Main program				#
#########################################

while getopts ":hpCcvxr:F:mPL:" opt; do
	case $opt in
		h)	# display help
		  	Help
		    	exit;;
		p)  	# Generate private key
			generate_PK
		    	;;
		C)  	# Generate csr
			generate_CSR
			;;
		c)  	# Issue certificate
			create_cert
			;;
		v)	# Verify
			verify
			;;
		x)	# Convert certificate format
			convert
			;;
		r)	#  Revoke certificate
			revoke
			;;
		F)	# Fetch certificate
			fetch
			;;
		m)	# Check pk cert match
			match
			;;
		P)	# Extract pub key
			extract_pub
			;;
		L)	# Get CRL
			get_crl
			;;
		\?) 	# invalide option
		    	echo "Error: Invalid option"
		    	exit 22;;
	esac
done

if [ $OPTIND == 1 ]; then
	echo -e "\e[31mERROR\e[0m: Invalid option. View \e[35m./crt_manager.sh -h\e[0m for more information"

fi
