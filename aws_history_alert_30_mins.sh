#!/bin/bash

#alert 2 aws history alert
#execute it : sh dba/aws_history_alert_30_mins.sh metrics-prod-master.cpenagls1m4q.us-west-2.rds.amazonaws.com 5432 analyze_monitor_db >> /home/postgres/dba/aws_history_alert_30_mins.log 2>&1


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

pg_aws_history_alert_30_mins=`psql -h $HOST -U analyze_monitor $DATABASE -tc "select environment_type,customer_name,db_name,task_name,max(timeslot) as max_timelot,age(now(),max(timeslot)) as since_last_run from monitoring.v_awsdms_history group by environment_type,customer_name,db_name,task_name having age(now(),max(timeslot))  > '00:30:00';"`

if [ -z "$pg_aws_history_alert_30_mins" ];
then

        echo ">> No queries more than 30 min. Exiting..."
                echo
else

        echo " DMS has not run for past 30 minutes "
        echo
        echo "$pg_aws_history_alert_30_mins"
      echo "$pg_aws_history_alert_30_mins" | /usr/bin/mail -s "DMS has not run for past 30 minutes on $HOST" analyze_alert@gobalto.com
#        echo "$pg_aws_history_alert_30_mins" | /usr/bin/mail -s "There are queries running more than 30 min on $HOST" rajesh.madiwale@openscg.com
        echo "Exiting...."
        exit_prog 0
fi

exit_prog 0
