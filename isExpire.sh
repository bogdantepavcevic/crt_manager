#! /bin/bash


for c in $(cat /home/bogdan/PROJECT/VERZIJA-EN/certsList.txt); do
	openssl s_client -showcerts -connect $c 2>/dev/null 1>/home/bogdan/PROJECT/VERZIJA-EN/tmp.crts < /dev/null
	T=$(cat /home/bogdan/PROJECT/VERZIJA-EN/tmp.crts | openssl x509 -text -noout | grep 'Not After' | sed -E "s/Not After\s:\s+//")
	A=$(($(date -d "$T" +%s) - $(date -d "$(date)" +%s)))
	if ((A/60/60/24 < 10))
	then
		echo -e "WARNING: Certificate for $(echo $c | cut -f 1 -d ":") expire in $((A/60/60/24)) days" >> /home/bogdan/PROJECT/VERZIJA-EN/tmpMail.txt
	fi
done

cat /home/bogdan/PROJECT/VERZIJA-EN/tmpMail.txt | mail -s "Certificate expire soon" bogdantepavcevic@gmail.com
rm /home/bogdan/PROJECT/VERZIJA-EN/tmpMail.txt


