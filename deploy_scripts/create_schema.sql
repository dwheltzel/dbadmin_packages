-- create_schema.sql 
-- Author: dheltzel


create user &&1 identified by "&&2";
grant connect,resource to &&1;
grant unlimited tablespace to &&1;

grant select on SYS.DBA_SCHEDULER_JOBS to &&1;
grant select on SYS.DBA_TAB_PARTITIONS to &&1;
grant select on SYS.DBA_TAB_SUBPARTITIONS to &&1;
grant select on SYS.DBA_PARALLEL_EXECUTE_TASKS to &&1;
grant select on SYS.DBA_PARALLEL_EXECUTE_CHUNKS to &&1;

