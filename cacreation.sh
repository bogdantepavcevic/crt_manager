#! /bin/bash

current_dir=$(pwd)


dpkg -s openssl &> /dev/null
if [ $? == 0 ]
then
        echo -e "\n\e[32mOK\e[0m: openssl is install";
else
        echo -e "\e[31mERROR\e[0m: openssl isn't installed. Install openssl and try again."
        exit 10
fi



if [ $(id -u) -ne 0 ];
then
        echo -e "\e[31mERROR\e[0m: This script must be run as root user!"
        exit 11
else
        echo -e "\e[32mOK\e[0m: Root privileges confirmed!\n"
fi



	echo "Please select the type of Certificate Authority (CA) to create. If you select first option,"
	echo "you can create secure and robust multi-tier PKI environment using both a Root and one or"
	echo "more Intermediate CAs. Alternatlively, the  Root CA alone can be used as a simple Self-signed"
	echo "CA for lab and testing purposes. The second option creates an Intermediate CA, but only if"
	echo "you already have a Root CA in place."
	echo "(1)   Root CA"
	echo "(2)   Intermediate CA"
while true; do
	read -p "Enter one of the option: " t
	case "$t" in
		1 )
			"$current_dir"/CA/scripts/rootCAcreation.sh
			break
			;;
		2 )
			"$current_dir"/CA/scripts/intermediateCAcreation.sh
			break
			;;
		* )
			echo -e "\e[31mERROR\e[0m: Invalid option!"
			;;
	esac
done
