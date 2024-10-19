#!/usr/bin/env bash
# Script to use when initialising an lxc
# in proxmox to get its IP address before
# marking the deployment complete
set -e

eval "$(jq -r '@sh "INAME=\(.iname) LXC_ID=\(.lxc_id) TOKEN=\(.token)"')"
IF_BLOCK=

CURL_COMMAND=(
	curl
	-s
	-H "Authorization: PVEAPIToken=root@pam!terraform=${TOKEN}"
	"https://pve.home:8006/api2/json/nodes/pve/lxc/${LXC_ID}/interfaces"
)

while true; do
	IF_BLOCK=$(\
	  "${CURL_COMMAND[@]}" | \
		  jq --arg name ${INAME} \
		  '.data[] | select(.name==$name)' \
    )
	
	# Checking if the interface has received an IP
	# from the the dhcp server yet. Break out of loop
	# when it does.
	[[ $(jq 'has("inet")' <<<${IF_BLOCK}) == true ]] && break
	
	sleep 2
done

# Terraform wants an object return so oblige it
jq '.inet | gsub("\/.*"; "") | {"ip_address": .}' <<<${IF_BLOCK}
