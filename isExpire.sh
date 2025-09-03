#! /bin/bash

current_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"


for c in $(cat "$current_dir"/certsList.txt); do
	openssl s_client -showcerts -connect $c 2>/dev/null 1>"$current_dir"/tmp.crts < /dev/null
	T=$(cat "$current_dir"/tmp.crts | openssl x509 -text -noout | grep 'Not After' | sed -E "s/Not After\s:\s+//")
	A=$(($(date -d "$T" +%s) - $(date -d "$(date)" +%s)))
	if ((A/60/60/24 < 10))
	then
		echo -e "WARNING: Certificate for $(echo $c | cut -f 1 -d ":") expire in $((A/60/60/24)) days"
	fi
done



