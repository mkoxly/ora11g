#!/bin/bash
# by nick 2015-12-05
[ $USER != "oracle" ]&& exit 1
source ~/.bash_profile
now=`date +"%F_%H-%M-%S"`
logfile=`dirname $0`/log/backupdb_${now}.rman.log
mntlog=`dirname $0`/log/mnt_backupdb_${now}.rman.log
bkpath="/home/oracle/rman/backup"
tag="full${now}"
kept=14
#sqlplus / as sysdba >/tmp/current_scn <<EOF
#select 'scn='||current_scn scn from v\$database;
#EOF
#current_scn=`grep scn /tmp/current_scn|awk -F"=" '{print $2}'`
format="%d-%I-%T_%U"
echo "`date +"%F %T"` Now begin to backup ......" >>$logfile
rman target / >>${logfile}  <<EOF
RUN
{
    configure retention policy to recovery window of $kept days;
    CONFIGURE BACKUP OPTIMIZATION ON;
    configure controlfile autobackup on;
    configure controlfile autobackup format for device type disk to '${bkpath}/%F';
    allocate channel ch1 type disk;
    allocate channel ch2 type disk;
    allocate channel ch3 type disk;
    allocate channel ch4 type disk;
    sql "alter system archive log current";
    backup as compressed backupset database skip inaccessible tag '$tag' format '${bkpath}/fulldb_${format}';
    sql "alter system archive log current";
   # backup  archivelog  from scn ${current_scn} format '${bkpath}/arch_${format}';
    backup  archivelog all  format '${bkpath}/arch_${format}' not backed up;
    backup current controlfile format '${bkpath}/ctl_${format}';
    backup spfile format '${bkpath}/spfile_${format}';
   }  
EOF
echo "`date +"%F %T"` backup finish ......" >>$logfile
rman target / >>$mntlog <<EOF1
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
find `dirname $0` -type f -name "*.rman.log" -mtime +${kept} -exec rm -rf {} \;
