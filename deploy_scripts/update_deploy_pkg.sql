-- update_deploy_pkg.sql
-- Author: dheltzel

-- Update packages
SET feed OFF
SET lines 150
SET pages 0
SET trimspool ON
COL spool_name FOR a40 new_value spool_name
SELECT 'UpdateDeployUtils_'||NAME||'_'||to_char(SYSDATE,'YYMMDDHH24MI')||'.sql' spool_name from v$database;
SPOOL /home/oracle/logs/&spool_name

--grant select on sys.dba_scheduler_jobs to DBADMIN;
drop table DDL_AUDIT_LOG;
@tables/ddl_audit_log.sql

@packages/audit_pkg_body.sql
@packages/deploy_utils_spec.sql
@packages/deploy_utils_body.sql
SET serverout ON SIZE UNLIMITED
BEGIN deploy_utils.pkg_info; END;
/

EXIT
