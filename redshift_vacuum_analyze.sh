BINDIR=/usr/bin
HOST=$1
T_PORT=$2
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


dbnames=`$BINDIR/psql -p $T_PORT -U skshirsagar -h $HOST template1 -c "select distinct datname FROM pg_database WHERE datname NOT IN ('template0')" -t`;
for dbname in $dbnames
do
   echo "Vacuumin DATABASE: $dbname";
   $BINDIR/psql -p $T_PORT -U skshirsagar -h $HOST -d "$dbname" -c "vacuum" -t;
   $BINDIR/psql -p $T_PORT -U skshirsagar -h $HOST -d "$dbname" -c "analyze" -t;
done;
ENDTIME=$(date +%s)
secs=$(($ENDTIME - $STARTTIME))
printf 'Elapsed Time %dh:%dm:%ds\n' $(($secs/3600)) $(($secs%3600/60)) $(($secs%60))

exit_prog 0 

