BINDIR=/usr/bin
HOST=$1
T_PORT=$2

exit_prog() {
        echo
        echo "END TIME = `date +%Y%m%d_%H%M%S`"
        echo
        echo ============================================================================================
        echo
        exit $1
}

failed_slots=`psql -h $HOST -U dbmaintain template1 -c "select slot_name,database,(case when active = 'true' then 'active' else 'failed' end) active from pg_replication_slots where active = 'false';" -t`

if [ -z "$failed_slots" ];
then

        echo ">> No failed replication slots found. Exiting..."
                echo
else

        echo "There are failed replication slots: "
        echo
        echo "$failed_slots"
	echo "$failed_slots" | /usr/bin/mail -s "Failed replication slots on $HOST" critical_db@gobalto.com 
        echo "Exiting...."
        exit_prog 0
fi

exit_prog 0
