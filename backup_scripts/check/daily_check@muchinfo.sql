set linesize 160 pagesize 9999;
Set timing on
Alter session set nls_date_format='YYYY-MM-DD HH24:MI:SS';
host clear
Prompt 表空间统计
select nvl(tname,'<ALL>') tname,sum(max_gb)"Max_Gb",sum(size_gb) "Size_Gb",sum(used_gb) "Used_Gb",sum(free_gb) "Free_Gb",max("%Used") "%Used",max("%Max_Used") "%Max_Used" from (
select f.ts tname,round(total/1024/1024/1024,2) Max_Gb ,round(f.alloc/1024/1024/1024,2) Size_Gb,round((alloc-nvl(free,0))/1024/1024/1024,2) Used_Gb,round(free/1024/1024/1024,2) Free_Gb,
round((alloc-nvl(free,0))/alloc*100,2) "%Used",
round((alloc-nvl(free,0))/total*100,2) "%Max_Used" from 
(select tablespace_name ts,sum(decode(autoextensible,'YES',maxbytes,bytes)) total,sum(bytes) alloc from dba_data_files group by tablespace_name) f,
(select tablespace_name ts,sum(bytes) free from dba_free_space  group by tablespace_name) r
where f.ts = r.ts(+)
union all
select f.ts,round(total/1024/1024/1024,2) total_gb ,round(alloc/1024/1024/1024,2) ,round(used/1024/1024/1024,2) used_gb,round((alloc-used)/1024/1024/1024,2) free_gb,
 round(used/alloc*100,2) ,round(used/total*100,2) max_used_per from
(select tablespace_name ts,sum(decode(autoextensible,'YES',maxbytes,bytes)) total,sum(bytes) alloc from dba_temp_files group by tablespace_name ) f,
(select ts,blks*bs used from (select tablespace_name ts,sum(used_blocks) blks from gv$sort_segment group by tablespace_name) 
,(select value bs from v$parameter where name = 'db_block_size')) r
where f.ts = r.ts) group by rollup(tname) order by "%Max_Used"  ;
-- asm dg 统计
select name,round(total_mb/1024,2) total_gb, round(free_mb/1024,2) free_gb,round((total_mb-free_mb)/1024,2) used_gb,
round((total_mb-free_mb)/total_mb*100,2) used_per from V$ASM_DISKGROUP;
--业务表空间统计
select round(sum(total)/1024/1024/1024,2) total,round(sum(used)/1024/1024/1024,2) used,
round(sum(case when tbs in('TAS','BANK') then total else 0 end)/1024/1024/1024,2) b_toal,
round(sum(case when tbs in('TAS','BANK') then used else 0 end)/1024/1024/1024,2) b_used from
(select d.tbs,total,free,total-free used from 
(select tablespace_name tbs ,sum(bytes) total from dba_data_files  group by tablespace_name) d,
(select tablespace_name tbs,sum(bytes) free from dba_free_space  group by tablespace_name) f
where d.tbs = f.tbs(+));
--数据库信息
 select name,log_mode,controlfile_type,open_mode,protection_mode,database_role,switchover_status from v$database;
select host_name,instance_name,status,trunc(sysdate-startup_time,2) uptime_day from v$instance;
--大对象
select * from (
select owner,segment_name,sum(bytes)/1024/1024/1024 gb from dba_segments where tablespace_name='TAS' group by owner,segment_name
order by 3 desc) where rownum<=10;
--PGA
select * from (
select spid,pname,program, round(pga_used_mem/1024/1024,2) pga_used_mb,round(pga_alloc_mem/1024/1024,2) pga_alloc_mb,
round(pga_max_mem/1024/1024,2) pga_max_mb  from v$process order by pga_used_mb desc ) where rownum<=10 order by pga_used_mb ;
--SGA
select name,round(bytes/1024/1024,2) mb,resizeable  from v$sgainfo order by 2;
select name ,decode(unit,'bytes',round(value/1024/1024,2),value) value_mb from v$pgastat where name in ('total PGA inuse','maximum PGA allocated','process count',
'max processes count','cache hit percentage');
--select * from v$managed_standby;
--select * from v$archive_dest_status ;
--Select * from (select * from v$dataguard_status order by timestamp desc) where rownum<=20 ;
--select * from v$redo_dest_resp_histogram;
--DATAGUARD status
select * from (
  select a.THREAD#,a.SEQUENCE#,a.FIRST_TIME,
  case when ( c.n>1 and (b.APPLIED is null or b.APPLIED<>'YES')) then 'ERROR' else 'OK' end  dgstatus,
  a.ARCHIVED a_archived,a.APPLIED a_applied,a.DELETED a_deleted,b.ARCHIVED b_archived,b.APPLIED b_applied ,b.DELETED b_deleted,
  row_number()over(partition by a.thread# order by a.SEQUENCE# desc) ord from 
  (select * from v$archived_log where dest_id=1)  a , (select * from v$archived_log where dest_id=2) b,
  (select count(*) n from v$parameter where name like 'log_archive_dest%' and name not like 'log_archive_dest_stat%' and value is not null) c
 where a.THREAD# = b.thread#(+) and  a.SEQUENCE# = b.SEQUENCE#(+)   
) where ord<=15
order by ord,thread#;
show parameter log_archive_config;
show parameter log_archive_dest_1;
archive log list;
	
-- long transaction
select gt.inst_id,
       gt.start_Time,
       round((sysdate - to_date(gt.start_Time, 'mm/dd/yy hh24:mi:ss')) * 24 * 60,  1) elapsed_min,
       gt.status,
       gs.sid,
       gs.SERIAL#,
       gs.OSUSER,
       gs.username,
       gs.PROGRAM,
       gs.MACHINE,do.OWNER,do.OBJECT_NAME locked_objects
  from gv$transaction gt, gv$session gs,gv$locked_object gl,dba_objects do
 where gt.addr = gs.TADDR
   and gs.sid = gl.SESSION_ID
   and gl.OBJECT_ID = do.OBJECT_ID
      and do.OBJECT_NAME<>'TEMPACCOUNTCODE'
 order by elapsed_min desc;
--lock
select O.name objname, O.type# objtype, U.name objowner, L2.*, O.subname
from
(select /*+ rule */ 0, S.sid, S.serial#, nvl(S.sql_id,0) ,DECODE(L.type, 'TM', L.id1, 'TX', decode(L.request, 0, NVL(LO.object_id,-1), S.row_wait_obj#), -1) AS object_id ,S.username, S.row_wait_obj#, S.row_wait_block# ,S.row_wait_row#, S.row_wait_file#, L.type ,decode(L.lmode, 0, 'NONE', 1, 'NULL', 2, 'ROW SHARE', 3, 'ROW EXCLUSIVE', 4, 'SHARE', 5, 'SHARE ROW EXCLUSIVE', 6, 'EXCLUSIVE', '?') ,decode(L.request, 0, 'NONE', 1, 'NULL', 2, 'ROW SHARE', 3, 'ROW EXCLUSIVE', 4, 'SHARE', 5, 'SHARE ROW EXCLUSIVE', 6, 'EXCLUSIVE', '?') ,L.id1, L.id2, L.ctime ,P.spid, S.sql_hash_value
from v$lock L, v$session S, v$process P,
(select object_id,session_id,xidsqn
from v$locked_object
where xidsqn >0) LO
where S.sid = L.sid and P.addr = S.paddr and L.type != 'MR' and L.sid = LO.session_id(+) and L.id2 = LO.xidsqn(+) ) L2 ,sys."_CURRENT_EDITION_OBJ" O ,sys.user$ U
where O.obj#(+) = L2.object_id and O.owner# = U.user#(+) and U.type# != 2 and o.name<>'TEMPACCOUNTCODE';
--index
select DI.OWNER,TABLE_NAME,DI.index_name,DI.status from dba_indexes di where STATUS <>'VALID' and status<>'N/A';
select index_name,partition_name,dp.status from dba_ind_partitions dp where dp.status<>'USABLE';
select 'alter '||object_type||' '||owner||'.'||object_name||' compile;' compilesql from dba_objects where status<>'VALID';
	select 'exec dbms_ijob.broken('||job||',true);' bsql,broken,what from dba_jobs where upper(what) like '%DBMS_REFRESH%';
--ALTER PROFILE DEFAULT LIMIT PASSWORD_LIFE_TIME UNLIMITED;
--redo间隔
Select * from (
select thread#,sequence#,first_time, round((end_time-first_time)*24*60,2) interv_minutes from ( 
select thread#,sequence#,first_time,lead(first_time)over(order by thread#,sequence#,first_Time) end_time from v$log_history 
where first_time >trunc(sysdate-3) order by thread#,sequence# desc ))where rownum<=30;
--REDO SWICH TIME 
Select * from (
select * from (select thread#,sequence#, first_time,   round((end_time - first_time) * 24 * 60, 2) interv_minutes
          from (select thread#, sequence#, first_time, lead(first_time) over(order by thread#, sequence#, first_Time) end_time
                  from v$log_history   where first_time > trunc(sysdate - 3)))
 where interv_minutes <= 5 order by thread#, sequence# desc ) where rownum<=10; 
 --REDO LOGS PER HOUR
Select * from ( select thread#,to_char(first_time,'yyyy-mm-dd hh24') period,count(*) logs from v$log_history  where first_Time>trunc(sysdate)-14
 group by  thread#,to_char(first_time,'yyyy-mm-dd hh24') having count(*) >=20
 order by 1 desc) where rownum<=10 ;


--SQL多版本问题
--select s.sql_id,c.cnt,s.sql_text from v$sqlarea s,(select sql_id,cnt from (select sql_id ,count(*) cnt  from v$sql_shared_cursor  group by sql_id order by 2 desc) where rownum<=10) c
--where s.sql_id = c.sql_id;

Prompt 检查备份
Prompt 归档检查
col seq# for a15
col normal_range for a40
col lost_arch format a15
col lost_range format a40
select thread#,minseq||'--'||maxseq seq#,
       to_char(begin_time,'yyyy-mm-dd hh24:mi')||' -- '||to_char(end_time,'yyyy-mm-dd hh24:mi') normal_range,
       round(end_time-begin_time,2) days,
       case when lag1 is not null then (lag1+1)||'--'||(minseq-1) else null end lost_arch,
       case when time1 is not null then to_char(time1,'yyyy-mm-dd hh24:mi')||' -- '||to_char(begin_time,'yyyy-mm-dd hh24:mi') else null end lost_range   
 from (select thread#,minseq,maxseq,begin_time,end_time,lag(maxseq)over(partition by thread# order by maxseq) lag1,
              lag(end_time) over(partition by thread# order by end_time) time1 
       from (select thread#, min(sequence#) minseq,  max(sequence#) maxseq,min(first_Time) begin_time,max(first_Time) end_time
             from (select thread#, sequence# - ord lv, first_time, sequence#
                   from (select thread#, sequence#, first_Time,dense_rank() over(partition by thread# order by sequence#) ord
                         from (select thread#, sequence#, first_Time from v$backup_archivelog_details
                               union all
                               select thread#, sequence#, first_time from v$archived_log  where deleted <> 'YES'  and dest_id=1)
                          )
                    )
             group by thread#, lv)
      );
--检查全备
Col  CHECKPOINT_TIME format a25
select to_char(min(CHECKPOINT_TIME),'yyyy-mm-dd hh24:mi') CHECKPOINT_TIME, count(*) tbs_num from v$backup_datafile_details group by session_key order by CHECKPOINT_TIME;
--
select  count(*) "在线用户数",
        sum(case when accounttype = 0 then 1 else 0 end) "投资者在线数",
        sum(case when accounttype = 1 then 1 else 0 end) "会员交易员在线数",
        sum(case when accounttype = 3 then 1 else 0 end) "综合会员管理员在线数",
        sum(case when accounttype = 4 then 1 else 0 end) "交易所管理员在线数"
from  tas.onlineaccount;
select  count(*) 平台用户总数 ,
        sum(case when accounttype = 0  then 1 else 0 end) 投资者开户激活总数,
        sum(case when accounttype = 1  then 1 else 0 end) 交易员开户激活总数,
        sum(case when accounttype = 3  then 1 else 0 end) 综合会员管理员总数,
        sum(case when accounttype = 4  then 1 else 0 end) 交易所管理员总数        
 from tas.loginaccount where accountstatus not in (0,3)  ;
--3天内下单延迟
Select * from (select t1.orderid,t1.entrusttime,t2.tradetime,TO_NUMBER(t2.tradetime - t1.entrusttime) * 24 * 60 * 60 delay  
  from tas.orderdetail t1, tas.orderdetaillog t2 
  where t1.orderid = t2.orderid 
   and ENTRUSTTIME >= sysdate - 3
   and ROUND(TO_NUMBER(t2.tradetime - t1.entrusttime) * 24 * 60 * 60) > 4
   and t1.ordertype in (100, 101) order by 4 desc) where rownum<=15;
--下单数
Select * from (
select to_char(tod.entrusttime,'yyyy-mm-dd hh24') by_day,count(*) orders from tas.orderdetail tod 
where tod.entrusttime >= trunc(sysdate)-3
group by to_char(tod.entrusttime,'yyyy-mm-dd hh24') having count(*)>3000
order by 1 desc) where rownum<=15 ;
