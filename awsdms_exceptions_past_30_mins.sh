#!/bin/bash

#alert 1 check if any awsdms exceptions for the past 30 mins
#execute it : sh dba/awsdms_exceptions_past_30_mins.sh metrics-prod-master.cpenagls1m4q.us-west-2.rds.amazonaws.com 5432 analyze_monitor_db >> /home/postgres/dba/awsdms_exceptions_past_30_mins.log 2>&1 


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

pg_query_every_30_minutes=`psql -h $HOST -U analyze_monitor $DATABASE -tc "select * from monitoring.v_awsdms_apply_exceptions where age(now(),\"ERROR_TIME\") < '00:30:00' order by environment_type,customer_name,db_name;"`

if [ -z "$pg_query_every_30_minutes" ];
then

        echo ">> no exceptions found. Exiting..."
                echo
else

        echo " Exceptions detected in DMS "
        echo
        echo "$pg_query_every_30_minutes"
      echo "$pg_query_every_30_minutes" | /usr/bin/mail -s "exceptions detected in DMS on $HOST" analyze_alert@gobalto.com
#        echo "$pg_query_every_30_minutes" | /usr/bin/mail -s "There are queries running more than 30 min on $HOST" rajesh.madiwale@openscg.com
        echo "Exiting...."
        exit_prog 0
fi

exit_prog 0
