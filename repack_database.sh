BINDIR=/usr/bin
HOST=$1
T_PORT=$2
dbname=$3
STARTTIME=$(date +%s)
BASE_DIR=`dirname $0`
LOCK_FILE=$BASE_DIR/`basename $0`.repack.lock

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




# Note the idle connections
$BINDIR/pg_repack -h $HOST -p $T_PORT -U dbmaintain -k $dbname
OUT=$?
  if [ $OUT -eq 0 ];then
    echo "pg_repack completed successfully on $dbname. "
  else
    echo "pg_repack failed. Exiting..."
    exit_prog 0
  fi

ENDTIME=$(date +%s)
secs=$(($ENDTIME - $STARTTIME))
printf 'Elapsed Time %dh:%dm:%ds\n' $(($secs/3600)) $(($secs%3600/60)) $(($secs%60))

exit_prog 0

