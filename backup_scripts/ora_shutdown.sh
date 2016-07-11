#!/bin/sh
#2017-05-26 by nick  ,
# shutdown oracle 
#set -x
IS_RAC=0    #single instance by default 
IS_RUNNING=1
check_is_rac ()
{
 ps -fe |grep pmon
 ps -fe |grep pmon|grep -v grep|grep -iq ASM
 [ $? -eq 0 ] && IS_RAC=1
 ps -fe |grep -v grep |grep -q _pmon_
 [ $? -ne 0 ] && IS_RUNNING=0
}
shutdown_rac()
{
CRSCTL=`su - grid -c "which crsctl"`
echo "$CRSCTL stop crs -f" 
date
$CRSCTL stop crs -f
date
$CRSCTL check cluster -all
return 0
}
shutdown()
{
 date
 su - oracle -c "lsnrctl stop;sqlplus / as sysdba <<eof
shutdown immediate;
exit
eof
"
date
}
main() {
check_is_rac
if [ $IS_RUNNING -eq 1 ]; then
 [ $IS_RAC -eq 1 ] && shutdown_rac 
 [ $IS_RAC -eq 0 ] && shutdown
fi
}
main  2>&1 |tee -a $0.log
