-- File $Id: update_deploy_pkg.sql 4160 2014-04-22 19:28:05Z dheltzel $
-- Modified $Author: dheltzel $ 
-- Date $Date: 2014-04-22 15:28:05 -0400 (Tue, 22 Apr 2014) $
-- Revision $Revision: 4160 $

-- Update packages
SET feed OFF
SET lines 150
SET pages 0
SET trimspool ON
COL spool_name FOR a40 new_value spool_name
SELECT 'UpdateDeployUtils_'||NAME||'_'||to_char(SYSDATE,'YYMMDDHH24MI')||'.sql' spool_name from v$database;
SPOOL &spool_name

grant select on sys.dba_scheduler_jobs to dbadmin;
drop table DBADMIN.DDL_AUDIT_LOG;
@tables/ddl_audit_log.sql

@packages/audit_pkg_body.sql
@packages/deploy_utils_spec.sql
@packages/deploy_utils_body.sql
SET serverout ON SIZE UNLIMITED
BEGIN dbadmin.deploy_utils.pkg_info; END;
/

EXIT
