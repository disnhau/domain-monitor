#!/bin/bash

# domain monitor
# author @disnhau

# MODIFIY YOUR INFORMATION HERE
# default is dir has this script
DIR_ROOT=$(dirname $0)
# DIR_ROOT="/path/to/your/dir/here"
TELE_TOKEN="your-telegram-bot-token"
TELE_CHAT_ID="your-chat-id"

# it is my dir on another file, you can ignore it
base=~/Dropbox/Secs/Secs/bin/bash_profile.sh
[ -f $base ] && . $base

[ -z "$(which subfinder)" ] && echo "please install subfinder first" && exit 0

LIST_DOMAINS_FILE=$DIR_ROOT/monitor-domains.txt
DOMAIN_DIR=$DIR_ROOT/monitor-domains
LOG_FILE=$DIR_ROOT/monitor-domains.log

# make dir/file
[ ! -d $DOMAIN_DIR ] && mkdir $DOMAIN_DIR
[ ! -f $LIST_DOMAINS_FILE ] && touch $LIST_DOMAINS_FILE

# help function
function help() {
	echo "---------------------------------------------------------------------------------------------------"
	echo "DIR has sub domains files: $DOMAIN_DIR"
	echo "FILE has domains to monitor: $LIST_DOMAINS_FILE"
	echo "---------------------------------------------------------------------------------------------------"
	echo ""
	echo "-d/--domain domain"
    echo "-v/--verbose verbose print, print more logs"
    echo "example"
    echo "- do in background"
    echo "----- ./script.sh -d domain.com -a cron"
    echo "- do add new domain to monitor"
    echo "----- ./script.sh -d domain.com"
	echo "---------------------------------------------------------------------------------------------------"
	exit 0
}

# logging
_log() {
	msg="$(date)|$1"
	echo "$msg" >> $LOG_FILE

	[ $DEBUG -eq 1 ] && echo $msg
}

# send telegram
telegram() {
    msg="$1"
    curl 2>/dev/null "https://api.telegram.org/bot$TELE_TOKEN/sendMessage?chat_id=$TELE_CHAT_ID&text=$msg"
}

# find sub domains
find_sub() {
	domain=$1
	temp_file=$(mktemp)
	subfinder -d $domain -silent -o $temp_file > /dev/null

	echo $temp_file
}

# return file stored sub domains
sub_file() {
	domain=$1
	sub=$DOMAIN_DIR/$domain.txt

	[ ! -f $sub ] && touch $sub
	echo $sub
}

# domain is monitoring?
domain_existed() {
	domain=$1

	grep "^${domain}$" $LIST_DOMAINS_FILE > /dev/null

	echo $?
}

# add domain to monitor file
add_domain_to_monitor() {
	domain=$1

	existed=$(domain_existed $domain)

	if [ $existed -eq 0 ]; then
		echo "domain $domain existed"
		exit 0
	fi

	echo $domain >> $LIST_DOMAINS_FILE
}

# check for new domain then push notification
diff_new_sub_domain() {
	new_data=$1
	old_sub_domain=$2

	while read domain; do
		grep "$domain" $old_sub_domain > /dev/null
		if [ $? -ne 0 ]; then
			echo "$domain" >> $old_sub_domain
			telegram "new $domain"
		fi
	done < $new_data
}

####################### main 

# domain to do
DOMAIN=""

# action: scan|cron
# scan add new domain
# cron run in background to check all domains
ACTION="scan"

# debug 0|1
DEBUG=0

while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    -d|--domain)
    DOMAIN="$2"
    shift
    shift
    ;;

    -v|--verbose)
    DEBUG="$2"
    shift
    shift
    ;;

    -a|--action)
    ACTION="$2"
    shift
    shift
    ;;

    -h|--help)
	help
    shift
    shift
    ;;

    *) 
	help
esac
done

set -- "${POSITIONAL[@]}"

if [ $ACTION = "scan" ]; then
	[ -z "$DOMAIN" ] && echo "no domain" && help

	is_new_domain=$(domain_existed $DOMAIN)

	_log "finding sub domains $DOMAIN"
	sub_file_temp=$(find_sub $DOMAIN)
	SUB_LIST_DOMAINS_FILE=$(sub_file $DOMAIN)

	# first time
	if [ $is_new_domain -ne 0 ]; then
		add_domain_to_monitor $DOMAIN

		cat $sub_file_temp > $SUB_LIST_DOMAINS_FILE
		rm -f $sub_file_temp
		exit 0
	fi

	# now check for new sub domain
	diff_new_sub_domain $sub_file_temp $SUB_LIST_DOMAINS_FILE
	rm -f $sub_file_temp
elif [ $ACTION = "cron" ]; then
	while read DOMAIN; do
		_log "===============> CRONJOB"
		_log "checking $DOMAIN"

		sub_file_temp=$(find_sub $DOMAIN)
		SUB_LIST_DOMAINS_FILE=$(sub_file $DOMAIN)
		diff_new_sub_domain $sub_file_temp $SUB_LIST_DOMAINS_FILE

		rm -f $sub_file_temp
	done < $LIST_DOMAINS_FILE
else
	echo "nothing to do"
fi

echo "DONE"