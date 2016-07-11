#!/bin/bash
. ~/.bash_profile
echo "[ `date` ] begin to clean archive logs" >$0.log
rman target / >>$0.log <<EOF
crosscheck backup;
crosscheck archivelog all;
crosscheck copy;
delete force noprompt archivelog until time 'sysdate - 5';
delete noprompt obsolete;
delete noprompt expired  backup;
delete noprompt expired  archivelog all;
EOF
echo "[ `date` ] Done!" >>$0.log