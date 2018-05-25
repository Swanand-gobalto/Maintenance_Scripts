#!/bin/bash

#pg logs rotation: repo-uat
#00      10      1       *       *       sh /var/lib/postgresql/dba/pg_log_rotation.sh > /var/lib/postgresql/dba/db_log_rotation.log 2>&1

BASE_DIR=`dirname $0`
LOCK_FILE=$BASE_DIR/`basename $0`.lock


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

# Logical backup script

db_server="127.0.0.1"
db_logs_dir="/data/pglogs"
if_oldr_thn_archive_days=5;
n_retention_days=60
script_dir="/var/lib/postgresql/dba/"
timeslot=`date +%Y%m%d_%H%M%S`
dateformat=`date +%Y-%m-%d`

#------------------------------------------------------------------------
#Archiving DATABASE LOG FILES OLDER THEN "if_oldr_thn_archive_days" DAYS
#------------------------------------------------------------------------
log_message "Running retention logic : Logs older than $if_oldr_thn_archive_days days will be archived to tar.gz"

cd $db_logs_dir

/bin/ls $db_logs_dir | egrep postgresql | egrep 'log$' | while read -r line;
do
        createDate=`echo $line | egrep postgresql | egrep log | awk -F'postgresql-' {'print $2'} | awk -F'_' {'print $1'} | awk -F'.' {'print $1'}`
	createDate=`date -d "$createDate" +%s`
        olderThan=`date -d "-$if_oldr_thn_archive_days days" +%s`


        if [ "$createDate" -lt "$olderThan" ]; then
			echo "Files to archive..."
				tarName=`echo "$line" | cut -d'.' -f1`
				echo "$tarName.tar.gz"
				 /bin/ls $line | /usr/bin/xargs /bin/tar -czf $tarName.tar.gz

		fi
done;


#----------------------------------------------------------------------------------
#Deleting [*.log] DATABASE LOG FILES OLDER THEN "if_oldr_thn_archive_days" i.e. 30 DAYS
#----------------------------------------------------------------------------------


/bin/ls $db_logs_dir | egrep postgresql | egrep 'log$' | while read -r line;
do
        createFileDate=`echo $line | egrep postgresql | egrep 'log*' | awk -F'postgresql-' {'print $2'} | awk -F'_' {'print $1'} | awk -F'.' {'print $1'}`
        createFileDate=`date -d "$createFileDate" +%s`
        olderThanDel=`date -d "-$if_oldr_thn_archive_days days" +%s`

    if [ "$createFileDate" -lt "$olderThanDel" ]; then
#                echo "Deleting file - $line"
		rm $db_logs_dir/$line

        fi
done;


#------------------------------------------------------------------------
#Deleting archived [tar.gz] DATABASE LOG FILES OLDER THEN "n_retention_days" DAYS
#------------------------------------------------------------------------


/bin/ls $db_logs_dir | egrep postgresql | egrep 'tar.gz|log*' | while read -r line;
do
	createArchDate=`echo $line | egrep postgresql | egrep 'tar.gz' | awk -F'postgresql-' {'print $2'} | awk -F'_' {'print $1'} | awk -F'.' {'print $1'}`
	createArchDate=`date -d "$createArchDate" +%s`
	olderThanDel=`date -d "-$n_retention_days days" +%s`

    if [ "$createArchDate" -lt "$olderThanDel" ]; then
		echo "Deleting tar.gz file - $line"
#		    echo $line
	            rm $db_logs_dir/$line


	fi
done;

log_message "Retention logic completed"

cd $script_dir
echo

exit_prog 0
