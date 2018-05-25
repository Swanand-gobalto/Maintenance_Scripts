BINDIR=/usr/bin
HOST=$1
T_PORT=$2
DATABASE=$3
timeslot=`date +%b_%Y`
exit_prog() {
        echo
        echo "END TIME = `date +%Y%m%d_%H%M%S`"
        echo
        echo ============================================================================================
        echo
        exit $1
}


psql -h $HOST -U dbmaintain $DATABASE -c "\copy (SELECT accounts.name as account_name, users.first_name, users.last_name, users.email, COUNT(audits.auditable_id) AS login_count FROM bh.users join bh.accounts ON users.user_account_id = accounts.id
JOIN bh.user_role_grants ON user_role_grants.user_id = users.id JOIN bh.roles ON roles.id = user_role_grants.role_id JOIN bh.role_permission_grants ON role_permission_grants.role_id = roles.id JOIN bh.permissions ON permissions.id = role_permission_grants.permission_id
JOIN bh.audits ON audits.auditable_id = users.id WHERE permissions.name = 'Site Nomination, Evaluation and Selection' AND auditable_type = 'User' AND audited_changes LIKE '{\"last_login_at%' AND audits.created_at >= date_trunc('month', (current_date - interval '1' month))
AND audits.created_at < date_trunc('month', current_date) AND accounts.name IN ('PSI','GSK','PPD') GROUP BY accounts.name, users.first_name, users.last_name, users.email, auditable_id) TO '/home/postgres/dba/citeline_csv_$timeslot.csv' (FORMAT CSV, DELIMITER ',')"

if [ -s /home/postgres/dba/citeline_csv_$timeslot.csv ];
then

        echo ">> CSV is created. Sending Email.."
        echo
	/usr/bin/mail -s "Citeline CSV for $timeslot" citeline_csv@gobalto.com < /home/postgres/dba/citeline_csv_$timeslot.csv
	#/usr/bin/mail -s "Citeline CSV for $timeslot" swanand.kshirsagar@openscg.com < /home/postgres/dba/citeline_csv_$timeslot.csv


else

        echo "File does not exists OR empty file exists for $timeslot. Exiting without sending email..."
        echo
        exit_prog 0
fi

exit_prog 0
