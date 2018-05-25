#!/bin/bash

#alert 3 check past 24 hours
#execute it : sh dba/check_past_24_hours_queries.sh metrics-prod-master.cpenagls1m4q.us-west-2.rds.amazonaws.com 5432 analyze_monitor_db >> /home/postgres/dba/check_past_24_hours_queries.log 2>&1


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

pg_check_past_24_hours_queries=`psql -h $HOST -U analyze_monitor $DATABASE -tc "select e.environment_type,e.customer_name,e.db_name,e.script,e.start_time,e.run_time from monitoring.v_executions e where (e.run_time >'01:00:00' or (e.end_time is null and age(now(),e.start_time)>'01:00:00')) and e.start_time > date_trunc('hour', NOW() - interval '2 hours') order by e.environment_type,e.customer_name,e.db_name,e.script,e.start_time desc;"`

if [ -z "$pg_check_past_24_hours_queries" ];
then

        echo ">>No Hanging for the past 2 hours. Exiting..."
                echo
else

        echo "Hanging for the past 2 hours "
        echo
        echo "$pg_check_past_24_hours_queries"
      echo "$pg_check_past_24_hours_queries" | /usr/bin/mail -s "Materialization scripts haven't completed in 1 hour $HOST" analyze_alert@gobalto.com
#        echo "$pg_check_past_24_hours_queries" | /usr/bin/mail -s "Hanging for the past 24 hours on $HOST" rajesh.madiwale@openscg.com
        echo "Exiting...."
        exit_prog 0
fi

exit_prog 0
