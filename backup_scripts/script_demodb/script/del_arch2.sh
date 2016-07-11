#!/bin/bash
[ $USER != "oracle" ]&& exit 1
source ~/.bash_profile
now=`date +"%F_%H-%M-%S"`
logfile=`dirname $0`/log/del_arch_${now}.rman.log
mntlog=`dirname $0`/log/mnt_delarch${now}.rman.log
arch_kept=7
echo "`date +"%F %T"` Now begin to delete archive log ......" >>$logfile
rman target / >>$logfile   <<EOF
RUN
{
    allocate channel ch1 type disk;
    allocate channel ch2 type disk;
	delete force noprompt archivelog until time 'sysdate - $arch_kept';
    
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
echo "`date +"%F %T"`  finish ......" >>$logfile
find . -type f -name "*.rman.log" -mtime +${kept} -exec rm -rf {} \;


