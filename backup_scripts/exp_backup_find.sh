#!/bin/sh
# 2015-11-17 by nick
curpath=`dirname $0`
cd $curpath
curpath=`pwd`
logfile=${curpath}/export.log
cd ${curpath}/..
dir=`pwd`
date=`date "+%F_%H_%M_%S"`
copies=5 
cur_bkpath=${dir}/dump
compress=ALL
# ALL, DATA_ONLY, [METADATA_ONLY] and NONE.
parallel=1
backup(){
 cd $cur_bkpath
 echo "[ $(date "+%F %T") ]begin to export tas data ......." >>$logfile
 echo "schemas=tas,bank cluster=n directory=exp_tas_dir dumpfile=exp_${date}_%U logfile=expdp_${date}.log  COMPRESSION=${compress} parallel=${parallel} " >>$logfile
 expdp '" / as sysdba "' schemas=tas,bank cluster=n directory=exp_tas_dir dumpfile=exp_${date}_%U logfile=expdp_${date}.log  COMPRESSION=${compress} parallel=${parallel}
 if [ $? -eq 0 ] ; then
   echo "[ $(date "+%F %T") ] Export tas data successfully!!......." >>$logfile
 else
   echo "[ $(date "+%F %T") ] Export tas data failed !! ......." >>$logfile
 fi
 echo 'export data done!'
 find $cur_bkpath -type f -mtime +${copies} -exec rm {} \;
}
init(){
  [ -f ~/.profile ] && . ~/.profile
  [ -f ~/.bash_profile ] && . ~/.bash_profile
  mkdir -p $cur_bkpath  
  sqlplus / as sysdba <<EOF
  create or replace directory exp_tas_dir as '${cur_bkpath}';
  exit
EOF
}
init
backup &
