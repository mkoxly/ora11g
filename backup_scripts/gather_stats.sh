#!/bin/bash
echo "[ `date "+%F %T"` ] begin to gather schema stastics ...."  >>$0.log
[ -f ~/.bash_profile ] && . ~/.bash_profile
[ -f ~/.profile ] && . ~/.profile
sqlplus / as sysdba >>$0.log <<EOF
begin
  dbms_stats.gather_schema_stats(ownname => 'TAS',cascade => true,degree => 8);
  dbms_stats.gather_schema_stats(ownname => 'BANK',cascade => true,degree => 8);
end;
/
EOF
echo "[ `date "+%F %T"` ] Finish !!" >>$0.log