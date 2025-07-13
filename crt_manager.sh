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
	-c				Issue a certificate, signing of csr
	-v				Verify csr, certificate, private key
	-x				Change format of the certificate
	-r				Revoke certificate
	-F				Fetch certificate
	-m				Check the private key and certificate match


EXAMPLE:
	./crt_manager.sh -r certificateExample.crt
		Enter the path of certificate you want to revoke.

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
				echo -e "\e[31mERROR:\e[0m Private key must be 2048 or 4096 bits! "
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
        read -p "Provide the path to the openssl configuration file (openssl.cnf): " conf
        if test -f $conf  
        then
		read -p "Provide the path to the to private key: " pk
        	if test -f "$pk"
		then
			read -p "Enter the destination path for storing the csr : " csr
			if [ -n "$csr"]
			then
				openssl req -config $conf -new -sha256 -key $pk -out $csr | 2>/dev/null
			else
		                echo -e "\e[31mERROR\e[0m: The name of csr can't be empty string!"
                		exit 33
			fi
		else
			echo -e "\e[31mERROR:\e[0m Private key doesn't exist on specified path!"
			exit  32
		fi
	else
		echo -e "\e[31mERROR:\e[0m Configuration filed doesn't exist on specified path!"
		exit 31
	fi
}

create_CERT()
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
	echo -e " (s)   csr \n (c)   certificate \n (p)   private key \n (f)   pfx certificate"
	read -p "Select option: " opt
	case $opt in
		s)	# Verify csr
			read -p "Provide the path to the csr: " csr
			if test -f $csr
			then
				openssl req -text -noout -verify -in $csr
			else
				echo -e "\e[31mERROR:\e[0m Csr doesn't exist on specified path!"
			fi
			;;
		c)	# Verify certificate
			read -p "Provide the path to the certificate: " crt
			if test -f $crt
			then
				openssl x509 -text -noout -in $crt
			else
				echo -e "\e[31mERROR:\e[0m Certificate doesn't exist on specified path!"
			fi
			;;
		p)	# Verify private key 
			read -p "Provide the path to the private key: " pk
			if test -f $pk 
			then
				openssl rsa -check -in $pk
			else
				echo -e "\e[31mERROR:\e[0m Private key doesn't exist on specified path!"
			fi
			;;
		f)	# Verify pfx certificate
			read -p "Provide the path to the pfx certificate: " pfx
			if test -f $pfx
			then
				openssl pkcs12 -info -in $pfx
			else
				echo -e "\e[31mERROR:\e[0m Pfx certificate doesn't exist on specified path!"
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
	while [[ 1 ]]
	do
		if [[ $num>=1 ]] && [[ $num<=4 ]]
		then
			break
		else
			echo -e "\e[31mERROR:\e[0m Invalide number"
			exit 61
		fi
	done
	case $num in 
		1)	# DER -> PEM
			read -p "Provide the path in DER format: " cert
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
			read -p "Unesite sertifikat u PEM formatu: " cert
			if test -f $cert
			then
				cert_der=$cert'.der'
				openssl x509 -outform DER -in $cert -out $cert_der
			else
				echo -e "\e[31mERROR:\e[0m Certificate doesn't exist on specified path!"
				exit 73
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
	openssl ca -config /home/bogdan/PROJECT/opensslIntermediateCA.cnf -revoke $OPTARG 
}

fetch()
{
	read -p "Enter the path and file name  where certificate will be stored: " cert
	openssl s_client -showcerts -connect $OPTARG 2>/dev/null 1>$cert </dev/null
	cat $cert | openssl x509 -text -noout
}

check()
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
			 	echo -e "\e[31mERROR:\e[0m Certificate doe private key don't match!"
			exit 82
		fi
	else
		 echo "GRESKA: privatni kljuc ne postoji na zadatoj putanji!"
		exit 81
	fi
}


#########################################
# Main program				#
#########################################

while getopts ":hpCcvxr:F:m" opt; do
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
			create_CERT
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
			check
			;;
		\?) 	# invalide option
		    	echo "Error: Invalid option"
		    	exit 22;;
	esac
done

if [ $OPTIND == 1 ]; then
	echo -e "\e[31mERROR\e[0m: Invalid option. View \e[35m./crt_manager.sh -h\e[0m for more information"

fi
