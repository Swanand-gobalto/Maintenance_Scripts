BINDIR=/usr/bin
HOST=$1
T_PORT=$2
BASE_DIR=`dirname $0`

LOCK_FILE=$BASE_DIR/`basename $0`.analyze.lock

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

dbnames=`$BINDIR/psql -p $T_PORT -U dbmaintain -h $HOST template1 -c "select distinct datname FROM pg_database WHERE datname NOT IN ('postgres','template1','template0','rdsadmin')" -t`;
for dbname in $dbnames
do
  schemanames=`$BINDIR/psql -p $T_PORT -U dbmaintain -h $HOST -d "$dbname" -c "select distinct schemaname from pg_tables order by 1" -t`

  for schema in $schemanames
  do
    echo "Database: $dbname and Schema: $schema";
    tablenames=`$BINDIR/psql -p $T_PORT -U dbmaintain -h $HOST -d "$dbname" -c "select tablename from pg_tables where schemaname = '$schema' order by tablename" -t`
    for table in $tablenames
    do
      echo "Vacuumin TABLE: $table";
     $BINDIR/psql -p $T_PORT -U dbmaintain -h $HOST -d "$dbname" -c "analyze \"$schema\".\"$table\"" -t;
    done;
  done;
done;
ENDTIME=$(date +%s)
secs=$(($ENDTIME - $STARTTIME))
printf 'Elapsed Time %dh:%dm:%ds\n' $(($secs/3600)) $(($secs%3600/60)) $(($secs%60))

exit_prog 0






exit 1

