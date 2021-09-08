-- File $Id: create_base.sql 4160 2014-04-22 19:28:05Z dheltzel $
-- Modified $Author: dheltzel $ 
-- Date $Date: 2014-04-22 15:28:05 -0400 (Tue, 22 Apr 2014) $
-- Revision $Revision: 4160 $

SET serverout ON SIZE UNLIMITED
SET feed OFF
SET lines 150
SET pages 0
SET trimspool ON
COL spool_name FOR a40 new_value spool_name
SELECT 'InstallDeployUtils_'||db_unique_name||'_'||to_char(SYSDATE,'YYMMDDHH24MI')||'.sql' spool_name from v$database;
SPOOL &spool_name

-- Make grants to the dbadmin schema 
GRANT RESOURCE TO dbadmin;
ALTER USER dbadmin DEFAULT ROLE ALL;
GRANT SELECT ON sys.dba_editions TO dbadmin;
GRANT SELECT ON sys.dba_tab_privs TO dbadmin;
GRANT SELECT ON sys.dba_role_privs TO dbadmin;
GRANT SELECT ON sys.dba_synonyms TO dbadmin;
GRANT SELECT ON sys.dba_users TO dbadmin;
GRANT SELECT ON sys.dba_views TO dbadmin;
GRANT SELECT ON sys.dba_objects_ae TO dbadmin;
GRANT SELECT ON sys.dba_objects TO dbadmin;
GRANT SELECT ON sys.dba_parallel_execute_tasks TO dbadmin;
GRANT SELECT ON sys.dba_parallel_execute_chunks TO dbadmin;
GRANT SELECT ON sys.dba_roles TO dbadmin;
GRANT SELECT ON sys.dba_scheduler_jobs TO dbadmin;
GRANT SELECT ON sys.gv_$session TO dbadmin;
GRANT EXECUTE ON sys.dbms_lock TO dbadmin;

-- Create tables
--@tables/registrytable.sql
@tables/pkg_run_log.sql
@tables/err_log.sql
@tables/ddl_audit_log.sql
@tables/data_audit_log.sql
@tables/custom_except_handling.sql
@tables/action_audit_log.sql

-- Create packages
@packages/audit_pkg_spec.sql
@packages/audit_pkg_other.sql
@packages/audit_pkg_body.sql
@packages/deploy_utils_spec.sql
@packages/deploy_utils_body.sql

-- Verify the deploy is correct
BEGIN dbadmin.deploy_utils.pkg_info; END;
/
SPOOL OFF
EXIT
