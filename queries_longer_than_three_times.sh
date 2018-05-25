#!/bin/bash

#alert 4 queries running longer than three times avg run_time and over 10 minutes for the past 24 hours

#execute: sh dba/queries_longer_than_three_times.sh metrics-prod-master.cpenagls1m4q.us-west-2.rds.amazonaws.com 5432 analyze_monitor_db >> /home/postgres/dba/queries_longer_than_three_times.log 2>&1

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

pg_longer_than_three_times=`psql -h $HOST -U analyze_monitor $DATABASE -tc "select vs.environment_type,vs.db_name, vs.view,vs.start_time,vs.end_time,vs.run_time, vsa.three_times_avg from monitoring.v_stats vs left join  (select environment_type,db_name,view,avg(run_time),3*avg(run_time) as three_times_avg from monitoring.v_stats group by environment_type,db_name,view) as vsa  on vs.environment_type=vsa.environment_type and vs.db_name= vsa.db_name and vs.view= vsa.view
where vs.run_time > vsa.three_times_avg and vs.run_time > '00:10:00' and vs.start_time > date_trunc('hour', NOW() - interval '2 hours');"`

if [ -z "$pg_longer_than_three_times" ];
then

        echo ">> No queries are running longer than three times avg run_time and over 10 minutes for the past 2 hours. Exiting..."
                echo
else

        echo "View materialization is taking longer than usual "
        echo
        echo "$pg_longer_than_three_times"
      echo "$pg_longer_than_three_times" | /usr/bin/mail -s "View materialization is taking longer than usual $HOST" analyze_alert@gobalto.com
#        echo "$pg_longer_than_three_times" | /usr/bin/mail -s "queries running longer than three times avg run_time and over 10 minutes for the past 24 hours on $HOST" rajesh.madiwale@openscg.com
        echo "Exiting...."
        exit_prog 0
fi

exit_prog 0
