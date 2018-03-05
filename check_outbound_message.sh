# */10    *       *       *       *       sh dba/check_outbound_message.sh '<Host>' <Port> <DBname> >> /home/postgres/dba/outbound_central_prod.log 2>&1
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

outbound_messages=`psql -h $HOST -U skshirsagar $DATABASE -c "select customer_name, environment_name, count(*) from em_001.outbound_messages where status = 'trying' and created_at < (CURRENT_TIMESTAMP - INTERVAL '2 hour') group by customer_name, environment_name;" -t`

if [ -z "$outbound_messages" ];
then

        echo ">> No un-processed messages found. Exiting..."
                echo
else

        echo "There are un-processed messages found: "
        echo
        echo "$outbound_messages"
	#echo "$outbound_messages" | /usr/bin/mail -s "There are un-processed outbound messages found on $HOST" critical_event_message@gobalto.com
	echo "$outbound_messages" | /usr/bin/mail -s "There are un-processed outbound messages found on $HOST" swanand.kshirsagar@openscg.com
        echo "Exiting...."
        exit_prog 0
fi

exit_prog 0
