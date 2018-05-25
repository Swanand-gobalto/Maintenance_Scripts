BINDIR=/usr/bin
HOST='repo-dev.gobalto.com'
T_PORT=$1
STARTTIME=$(date +%s)
BASE_DIR=`dirname $0`
LOCK_FILE=$BASE_DIR/`basename $0`.lock

# Check that this process is not already running
if [ -f $LOCK_FILE ]
then
        echo ">> Process already running (`date`). Exiting...."
        exit 1
fi
echo $$ > $LOCK_FILE


exit_prog() {
        echo
        echo "END TIME = `date +%Y%m%d_%H%M%S`"
        echo
        echo ============================================================================================
        echo
        # Removing the lock file
        rm -f $LOCK_FILE
        exit $1
}



dbnames=`$BINDIR/psql -p $T_PORT -U skshirsagar -h $HOST template1 -c "select distinct datname FROM pg_database where datname not in ('postgres','template0','template1','rdsadmin')" -t`;

for dbname in $dbnames
do
  schemanames=`$BINDIR/psql -p $T_PORT -U skshirsagar -h $HOST -d "$dbname" -c "select distinct schemaname from pg_tables order by 1" -t`

  for schema in $schemanames
  do
     echo "Grant USAGE on - database: $dbname and schema : $schema"
     $BINDIR/psql -p $T_PORT -U skshirsagar -h $HOST -d "$dbname" -c "GRANT USAGE ON SCHEMA \"$schema\" TO dbmonitor" -t;
  
     echo "Granting SELECT on all tables - Database: $dbname Schema: $schema";
     $BINDIR/psql -p $T_PORT -U skshirsagar -h $HOST -d "$dbname" -c "GRANT SELECT ON ALL TABLES IN SCHEMA \"$schema\" TO dbmonitor" -t;
   
     echo "Setting default SELECT privileges for new tables"
     $BINDIR/psql -p $T_PORT -U skshirsagar -h $HOST -d "$dbname" -c "ALTER DEFAULT PRIVILEGES IN SCHEMA \"$schema\" GRANT SELECT ON TABLES TO dbmonitor;" -t;
  done;
done;
ENDTIME=$(date +%s)
secs=$(($ENDTIME - $STARTTIME))
printf 'Elapsed Time %dh:%dm:%ds\n' $(($secs/3600)) $(($secs%3600/60)) $(($secs%60))

exit_prog 0
