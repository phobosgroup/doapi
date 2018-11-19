#!/bin/bash
#
# A script written by viss (of phobos group) to simplify common
# operations with digital ocean. Ideally this should make
# doing these ops faster/easier, since they're not exactly intuitive
# feel free to hack up and submit pull requests.
# gpl version whatever, I don't care, I wrote this for my training
# classes to make my life easier. If you steal this and use it
# commercially you are authorizing me to have root on every box 
# which this script runs. thats my license. thems the rules.
# use it free? rad. use it for work? you owe me shells.
# yes i can find you, yes i will find you. 

# set your api key here!
api_key="git_yer_own"

# put a json array of your SSH key IDs here. 
# if you dont have that, run ./do_api --list-keys and I am will to be giving you thems.
# if you dont want to specify keys, comment the line out, otherwise the script may break
ssh_keys='["123","456","789","000"]'

if [[ -z $ssh_keys ]]; then
	echo "ssh keys not specified, you may not be able to login to droplets you create!"
	ssh_keys="null"
fi


# set your default region here
region="sfo2"

# TODO: 
# check to make sure jq is installed, and if it's not, complain and bail out

POSITIONAL=()
while [[ $# -gt 0 ]]
do
key=$1

case $key in
	--dns)
	dns="go go *burp* sanchez ski shoes!"
	echo "dns on: modifying hostname records for droplet"
	shift
	;;
	--subdomain)
	subdomain=$2
	subdomain=`echo $subdomain | xargs`
	shift
	shift
	;;
	--ip)
	ip=$2
	ip=`echo $ip | xargs`
	shift
	shift
	;;
	--domain)
	domain=$2
	shift
	shift
	;;
	--snapshot)
	snapshot=$2
	shift
	shift
	;;
	--hostname)
	hostname=$2
	if [[ $hostname ]]; then
		echo "hostname: $hostname"
	fi
	shift
	shift
	;;
	--region)
	region=$2
	shift
	shift
	;;
	--record)
	record=$2
	shift
	shift
	;;
	--size)
	size=$2
	shift
	shift
	if [[ -z $size ]]; then
		echo "size not specified, defaulting to s-1vcpu-2gb"
		size="s-1vcpu-2gb"
	fi
	;;
	--image)
	image=$2
	shift
	shift
	if [[ -z $image ]]; then
		echo "image not specified, defaulting to ubuntu-17-10-x64"
		image="ubuntu-17-10-x64"
	fi
	;;
	--list)
	#get names and ip addresses
	echo "listing droplets, regions and sizes.."
	curl -s -X GET -H "Content-Type: application/json" -H "Authorization: Bearer $api_key" "https://api.digitalocean.com/v2/regions" | jq -r '.[][] | select(.slug) .slug, .sizes' | perl -pe 's/\[\n|"|\]//g; s/,\n//g; s/\v+/\n/g; s/\h+/ /'
	echo "listing your existing droplets.."
	curl -s -X GET -H "Content-Type: application/json" -H "Authorization: Bearer $api_key" "https://api.digitalocean.com/v2/droplets" |  jq -r '.droplets[] | "\(.id) \(.name) \(.memory) \(.image.regions[0]) \(.networks.v4[]["ip_address"])"'
	POSITIONAL+=("$1")
	shift
	;;
	--list-droplets)
	echo "listing your existing droplets.."
	curl -s -X GET -H "Content-Type: application/json" -H "Authorization: Bearer $api_key" "https://api.digitalocean.com/v2/droplets" |  jq -r '.droplets[] | "\(.id) \(.name) \(.memory) \(.image.regions[0]) \(.networks.v4[]["ip_address"])"'
	POSITIONAL+=("$1")
	shift
	;;
	--list-snapshots)
	echo "listing your existing snapshots.."
	curl -s -X GET -H "Content-Type: application/json" -H "Authorization: Bearer $api_key" "https://api.digitalocean.com/v2/snapshots" |  jq -r '.snapshots[] | "\(.id) \(.name) \(.regions[])"'
	POSITIONAL+=("$1")
	shift
	;;
	--list-subdomains)
	if [[ -z $domain ]]; then
		echo "you must specify the domain (e.g hax.lol) you wish to retrieve records for"
		exit
	fi
	echo "listing subdomains for $domain"
	curl -s -X GET -H "Content-Type: application/json" -H "Authorization: Bearer $api_key" "https://api.digitalocean.com/v2/domains/$domain/records" | jq -r '.domain_records[] | "\(.id) \(.type) \(.name) \(.data)"'
	shift
	;;
	--add-subdomain)
	# need domain
	if [[ -z $domain ]]; then
		echo "you must enter a domain name for the record you wish to modify."
		exit
	fi
	if [[ -z $ip ]]; then
		echo "you must enter an IP for the record you want to add."
		exit
	fi
	if [[ -z $subdomain ]]; then
		echo "you must enter a subdomain for the record you want to add."
		exit
	fi
	# add a dns record
	read -r -d '' CMD <<- EOM
	'{"type":"A","name":"$subdomain","data":"$ip"}'
	EOM
	CMD=`echo $CMD | xargs`
	echo "CMD is $CMD"
	curl -s -X POST -H "Content-Type: application/json" -H "Authorization: Bearer $api_key" -d $CMD "https://api.digitalocean.com/v2/domains/$domain/records" | jq .
	POSITIONAL+=("$1")
	shift
	;;
	--del-subdomain)
	# get the ID of the subdomain
	todelete=`curl -s -X GET -H "Content-Type: application/json" -H "Authorization: Bearer $api_key" "https://api.digitalocean.com/v2/domains/$domain/records" | jq -r '.domain_records[] | "\(.name) \(.id)"' | grep $subdomain | cut -d " " -f 2 | perl -pe 's/"//g'`
	echo "Deleting $subdomain with id $todelete"
	curl -s -X DELETE -H "Content-Type: application/json" -H "Authorization: Bearer $api_key" "https://api.digitalocean.com/v2/domains/$domain/records/$todelete" | jq .
	POSITIONAL+=("$1")
	shift
	;;
	--delete-droplet)
	# did user give us everything we need?
	if [[ -z $hostname ]]; then
		echo "you must specify the hostname (or whatever name) you gave your droplet to delete it by name."
		exit
	fi
	# get existing list of droplet names
	DROPLETS=`curl -s -X GET -H "Content-Type: application/json" -H "Authorization: Bearer $api_key" "https://api.digitalocean.com/v2/droplets" | jq -r .droplets[].name`
	
	# is the name the user requested in the list of droplets?
	for droplet in $DROPLETS
	do
		if [[ $hostname = $droplet ]]; then
		todelete=$hostname
		fi
	done
	if [[ -z $todelete ]]; then
		echo "wasn't able to find the hostname you provided in the list of hosts available."
		exit
	fi
	# get the ID of the droplet
	id=`curl -s -X GET -H "Content-Type: application/json" -H "Authorization: Bearer $api_key" "https://api.digitalocean.com/v2/droplets" | jq -r '.droplets[] | "\(.name) \(.id)"' | grep $todelete | cut -d " " -f 2 | perl -pe 's/"//g'`
	# delete a droplet
	echo "deleting $todelete with id $id.."
	curl -X DELETE -H "Content-Type: application/json" -H "Authorization: Bearer $api_key" "https://api.digitalocean.com/v2/droplets/$id"
	POSITIONAL+=("$1")
	if [[ -n $dns ]]; then
                 # get existing list of  records
                subdomain=`echo $hostname | cut -d '.' -f 1 | xargs`
                domain=`echo $hostname | cut -d '.' -f 2,3 | xargs`
                echo "got $subdomain for subdomain to nuke"
                echo "got $domain for domain"
                record_id=`curl -s -X GET -H "Content-Type: application/json" -H "Authorization: Bearer $api_key" "https://api.digitalocean.com/v2/domains/$domain/records" |  jq -r '.domain_records[] | "\(.id) \(.name)"' | grep $subdomain | cut -d " " -f 1 | xargs`
                echo "got record_id $record_id"
                echo "nuking record for $subdomain / $domain"
                curl -s -X DELETE -H "Content-Type: application/json" -H "Authorization: Bearer $api_key" "https://api.digitalocean.com/v2/domains/$domain/records/$record_id" 
        fi

	shift
	;;
	--add-droplet)
	if [[ -z $hostname ]]; then
		echo "you must enter a name (or hostname) for the record you want to add."
		exit
	fi
	if [[ -z $region ]]; then
		echo "region not specified, defaulting to sfo2"
		region="sfo2"
	fi
	if [[ -z $size ]]; then
		echo "size not specified, defaulting to s-1vcpu-1gb"
		size="s-1vcpu-1gb"
	fi
	if [[ -n $snapshot ]]; then
		echo "using snapshot ID $snapshot in place of image. This will restore snapshot ID $snapshot over the droplet!"
		imagestring='"image":'"$snapshot"','
	else
		if [[ -z $image ]]; then
		echo "image not specified, defaulting to ubuntu-18-10-x64"
		imagestring='"image":"ubuntu-18-10-x64",'
		fi
	fi
	hostname=`echo $hostname | xargs`
	size=`echo $size | xargs`
	region=`echo $region | xargs`
	snapshot=`echo $snapshot | xargs`
	ssh_keys=`echo $ssh_keys | xargs`
	echo "opts: hostname $hostname region $region size $size"
	read -r -d '' CMD <<- EOM
	'{"name":"$hostname","region":"$region","size":"$size",$imagestring"ssh_keys":$ssh_keys,"backups":false,"ipv6":false}'
	EOM
	CMD=`echo $CMD | xargs`
	echo "CMD is $CMD"
	curl -s -X POST -H "Content-Type: application/json" -H "Authorization: Bearer $api_key" -d $CMD "https://api.digitalocean.com/v2/droplets" | jq '.droplet | "\(.name) \(.image.slug) \(.size.slug) \(.region.slug)"' 
	POSITIONAL+=("$1")
	if [[ -n $dns ]]; then
		echo "Waiting for droplet creation to settle"
	        sp='/-\|'
	        n=${#sp}
          	count=1
        	printf ' '
	        while [[ $count -le 600 ]]
	          do
		     printf "%s\b" "${sp:i++%n:1}"
		     sleep 0.1
		     count=$count+1
	          done
		 # get existing list of droplet names
		ip=`curl -s -X GET -H "Content-Type: application/json" -H "Authorization: Bearer $api_key" "https://api.digitalocean.com/v2/droplets" |  jq -r '.droplets[] | "\(.name) \(.networks.v4[]["ip_address"])"' | grep $hostname | cut -d " " -f 2 | xargs`
		echo "got $ip for ip"
		id=`curl -s -X GET -H "Content-Type: application/json" -H "Authorization: Bearer $api_key" "https://api.digitalocean.com/v2/droplets" | jq -r '.droplets[] | "\(.name) \(.id)"' | grep $hostname | cut -d " " -f 2 | perl -pe 's/"//g'`
		echo "got $hostname to add"
		subdomain=`echo $hostname | cut -d '.' -f 1 | xargs`
		domain=`echo $hostname | cut -d '.' -f 2,3 | xargs`
		echo "adding A record for $subdomain.$domain"
		curl -s -H "Authorization: Bearer $api_key" -H "Content-Type: application/json" -d '{"type":"A","name":"'"$subdomain"'","data":"'"$ip"'","ttl":60}' -X POST "https://api.digitalocean.com/v2/domains/$domain/records" | jq .
	fi
	shift
	;;
	*)
	POSITIONAL+=("$1")
	shift
	;;
esac

done
set -- "${POSTITIONAL[@]}"
