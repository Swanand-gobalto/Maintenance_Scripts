#!/bin/bash

BASE_DIR=`dirname $0`
LOCK_FILE=$BASE_DIR/`basename $0`.dbmon.lock

# Check that this process is not already running
if [ -f $LOCK_FILE ]
then
echo ">> Process already running (`date`). Exiting...."
exit 1
fi
echo $$ > $LOCK_FILE

log_message() {
	echo ">> `date +%Y%m%d_%H%M%S` : $1"
}

exit_prog() {
	# Removing the lock file
	echo
	rm -f $LOCK_FILE
	exit $1
}

pgc_dir=/opt/bigsql

#------------------------------
# Restart pgc services
#------------------------------
$pgc_dir/./pgc restart

if [ $? -eq 0 ]; then
  echo "monitoring services are restarted successfully."
 else
  echo "monitoring services are not restarted properly. Checking further..."
#-------------------------
# Checking status
#------------------------

 services_down = $($pgc_dir/./pgc status | grep 'not' | awk '{ print $1 }')

#-------------------------
# Starting services
#-------------------------
 if [ -n services_down ]; then

 for servs in $services_down
  do
   $pgc_dir/./pgc $servs start
   if [ $? -eq 0 ]; then
    echo "Service $servs started successfuly."
   else
    echo "Service $servs failed to start." | /usr/bin/mail -s "dbmonitor services not starting: $servs" swanand.kshirsagar@openscg.com
    exit_prog 1
   fi
   done;
 else
 echo "Services are up."
 fi
fi

exit_prog 0