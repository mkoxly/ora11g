#!/bin/bash
[ $USER != "oracle" ]&& exit 1
source ~/.bash_profile
now=`date +"%F_%H-%M-%S"`
logfile=`dirname $0`/log/backuparch_${now}.rman.log
mntlog=`dirname $0`/log/mnt_backuparch${now}.rman.log
bkpath="/home/oracle/rman/backup"
tag="arch${now}"
kept=14
arch_kept=3
format="%d-%I-%T_%U"
echo "`date +"%F %T"` Now begin to backup ......" >>$logfile
rman target / >>$logfile   <<EOF
RUN
{
    allocate channel ch1 type disk;
    allocate channel ch2 type disk;
    backup as compressed backupset archivelog  all delete input; 
   }  
EOF
rman target / >>$mntlog  <<EOF1
RUN
{
    report obsolete;
    crosscheck backup;
    crosscheck copy;
    delete noprompt expired backup;
    delete noprompt expired archivelog all;
    delete noprompt obsolete; 
}
EOF1
echo "`date +"%F %T"` backup finish ......" >>$logfile
find . -type f -name "*.rman.log" -mtime +${kept} -exec rm -rf {} \;


