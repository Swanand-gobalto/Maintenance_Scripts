BINDIR=/usr/bin
HOST=$1
T_PORT=$2
DATABASE=$3

exit_prog() {
        echo
        echo "END TIME = `date +%Y%m%d_%H%M%S`"
        echo
        echo ============================================================================================
        echo
        exit $1
}

outbound_messages=`psql -h $HOST -U skshirsagar $DATABASE -c "select count(*) from em_001.outbound_messages where status = 'failure' and customer_name = 'PPD Production';" -t`

if [ -z "$outbound_messages" ];
then

        echo ">> No failed messages found. Exiting..."
                echo
else

        echo "There are failed messages found for PPD: "
        echo
        echo "$outbound_messages"
	echo "$outbound_messages" | /usr/bin/mail -s "There are failed outbound messages for PPD " cx@gobalto.com 
#	echo "$outbound_messages" | /usr/bin/mail -s "There are un-processed outbound messages found on $HOST" swanand.kshirsagar@openscg.com 
        echo "Exiting...."
        exit_prog 0
fi

exit_prog 0
