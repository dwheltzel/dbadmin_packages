-- create_base.sql
-- Author: dheltzel

SET serverout ON SIZE UNLIMITED
SET feed OFF
SET lines 150
SET pages 0
SET trimspool ON
COL spool_name FOR a40 new_value spool_name
SELECT 'InstallDeployUtils_'||db_unique_name||'_'||to_char(SYSDATE,'YYMMDDHH24MI')||'.sql' spool_name from v$database;
SPOOL &spool_name

--ALTER USER &&1 DEFAULT ROLE ALL;
--GRANT SELECT ON sys.dba_editions TO &&1;
--GRANT SELECT ON sys.dba_tab_privs TO &&1;
--GRANT SELECT ON sys.dba_role_privs TO &&1;
--GRANT SELECT ON sys.dba_synonyms TO &&1;
--GRANT SELECT ON sys.dba_users TO &&1;
--GRANT SELECT ON sys.dba_views TO &&1;
--GRANT SELECT ON sys.dba_objects_ae TO &&1;
--GRANT SELECT ON sys.dba_objects TO &&1;
GRANT SELECT ON sys.dba_parallel_execute_tasks TO &&1;
GRANT SELECT ON sys.dba_parallel_execute_chunks TO &&1;
--GRANT SELECT ON sys.dba_roles TO &&1;
GRANT SELECT ON sys.dba_scheduler_jobs TO &&1;
--GRANT SELECT ON sys.gv_$session TO &&1;
--GRANT EXECUTE ON sys.dbms_lock TO &&1;

-- Create tables
PROMPT pkg_run_log.sql
@tables/pkg_run_log.sql
PROMPT err_log.sql
@tables/err_log.sql
PROMPT ddl_audit_log.sql
@tables/ddl_audit_log.sql
PROMPT data_audit_log.sql
@tables/data_audit_log.sql
PROMPT custom_except_handling.sql
@tables/custom_except_handling.sql
PROMPT action_audit_log.sql
@tables/action_audit_log.sql
PROMPT registrytable.sql
@tables/registrytable.sql

-- Create base packages
PROMPT pkg_audit_spec.sql
@packages/pkg_audit_spec.sql
PROMPT pkg_audit_other.sql
@packages/pkg_audit_other.sql
PROMPT pkg_audit_body.sql
@packages/pkg_audit_body.sql
PROMPT pkg_deploy_utils_spec.sql
@packages/pkg_deploy_utils_spec.sql
PROMPT pkg_deploy_utils_body.sql
@packages/pkg_deploy_utils_body.sql

--PROMPT Verify the deploy is correct
BEGIN pkg_deploy_utils.pkg_info; END;
/

-- Create extra packages
PROMPT pkg_trim_utils_spec.sql
@packages/pkg_trim_utils_spec.sql
PROMPT pkg_trim_utils_other.sql
@packages/pkg_trim_utils_other.sql &&1
PROMPT pkg_trim_utils_body.sql
@packages/pkg_trim_utils_body.sql
PROMPT pkg_registry_spec.sql
@packages/pkg_registry_spec.sql
PROMPT pkg_registry_other.sql
@packages/pkg_registry_other.sql
PROMPT pkg_registry_body.sql
@packages/pkg_registry_body.sql

SPOOL OFF
EXIT
