BINDIR=/usr/bin
HOST=$1
T_PORT=$2
USERNAME=$3
dbname='postgres'
BASE_DIR=`dirname $0`

# Note the idle connections
$BINDIR/psql -p $T_PORT -U $USERNAME -h $HOST -d "$dbname" -c "select pid,usename,now() as current_time,now()-state_change as idle_for,client_addr,substr(query,1,16) from pg_stat_activity where state='idle' and query_start < (now() - interval '5 min') ORDER BY 4 DESC;" >> terminated_idle_sessions.txt

#terminate idle connections
$BINDIR/psql -p $T_PORT -U $USERNAME -h $HOST -d "$dbname" -c "select pg_terminate_backend(pid) from pg_stat_activity where state='idle' and query_start < (now() - interval '5 min') limit 60;" >> terminated_idle_sessions.txt


exit 1

