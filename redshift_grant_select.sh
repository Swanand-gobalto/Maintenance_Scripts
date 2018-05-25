BINDIR=/usr/bin
HOST='redshift-shared-production.cuqmz6x0qm6h.us-west-2.redshift.amazonaws.com'
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
  
     tablenames=`$BINDIR/psql -p $T_PORT -U skshirsagar -h $HOST -d "$dbname" -c "select tablename from pg_tables where schemaname = '$schema' order by tablename" -t`
    
     for table in $tablenames
     do
       
       echo "Granting SELECT on table - Database: $dbname Schema: $schema Table: $table";
       $BINDIR/psql -p $T_PORT -U skshirsagar -h $HOST -d "$dbname" -c "GRANT SELECT ON TABLE \"$schema\".\"$table\" TO dbmonitor" -t;
     done;
  done;
done;


tablenames=`$BINDIR/psql -p $T_PORT -U postgres -d "$dbname" -c "select tablename from pg_tables where schemaname = '$schema' and tablename not in ('lb_locale','lb_genmap') order by tablename" -t`
    for table in $tablenames
    do
      echo "Vacuumin TABLE: $table";
     $BINDIR/psql -p $T_PORT -U postgres -d "$dbname" -c "vacuum analyze $schema.$table" -t;
    done;



ENDTIME=$(date +%s)
secs=$(($ENDTIME - $STARTTIME))
printf 'Elapsed Time %dh:%dm:%ds\n' $(($secs/3600)) $(($secs%3600/60)) $(($secs%60))

exit_prog 0
