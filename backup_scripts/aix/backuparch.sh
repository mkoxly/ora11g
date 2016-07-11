#!/bin/ksh
# aix
[ $USER != "oracle" ]&& exit 1
. ~/.profile
now=`date +"%F_%H-%M-%S"`
logfile=`dirname $0`/log/backuparch_${now}.rman.log
mntlog=`dirname $0`/log/mnt_backuparch${now}.rman.log
bkpath="/oracle/backup"
tag="arch${now}"
kept=14
arch_kept=3
format="%d-%I-%T_%U"
echo "$(date +"%F %T") Now begin to backup ......" >>$logfile
rman target / >>$logfile   <<EOF
RUN
{
    configure retention policy to recovery window of $kept days;
    CONFIGURE BACKUP OPTIMIZATION ON;
    configure controlfile autobackup on;
    configure controlfile autobackup format for device type disk to '${bkpath}/%F';
    CONFIGURE ARCHIVELOG DELETION POLICY TO NONE; 
    allocate channel ch1 type disk;
    allocate channel ch2 type disk;
  # backup as compressed backupset archivelog until time 'sysdate - $arch_kept' format '${bkpath}/arch_${format}' delete input ;
    backup as compressed backupset archivelog  all  format '${bkpath}/arch_${format}' not backed up;
    delete noprompt archivelog  until time 'sysdate - $arch_kept';
   }  
EOF
rman target / >>$mntlog  <<EOF1
RUN
{
    configure retention policy to recovery window of $kept days;
    CONFIGURE BACKUP OPTIMIZATION ON;
    configure controlfile autobackup on;
    configure controlfile autobackup format for device type disk to '${bkpath}/%F';
    report obsolete;
    crosscheck backup;
    crosscheck copy;
    delete noprompt expired backup;
    delete noprompt expired archivelog all;
    delete noprompt obsolete; 
}
EOF1
echo "$(date +"%F %T") backup finish ......" >>$logfile
find . -type f -name "*.rman.log" -mtime +${kept} -exec rm -rf {} \;
