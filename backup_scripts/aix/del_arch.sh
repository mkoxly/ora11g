#!/bin/ksh
logfile=$0.log
function do_del {
echo "ORACLE_SID:$ORACLE_SID" >> ${logfile}
echo "[ `date` ] begin to clean archive logs" >>${logfile}
rman target / >${logfile}.${ORACLE_SID} <<EOF
crosscheck backup;
crosscheck archivelog all;
crosscheck copy;
delete force noprompt archivelog until time 'sysdate - 5';
delete noprompt obsolete;
delete noprompt expired  backup;
delete noprompt expired  archivelog all;
EOF
echo "[ `date` ] Done!" >>$logfile
}
. ~/.profile 
export ORACLE_SID=tasxcstb
do_del
export ORACLE_SID=tascjstb
do_del

