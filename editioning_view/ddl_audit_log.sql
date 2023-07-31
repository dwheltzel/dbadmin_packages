BEGIN deploy_utils.log_deploy_info('DDL_AUDIT_LOG','data_audit_log.sql dheltzel'); END;
/

DROP VIEW DDL_AUDIT_LOG;
CREATE OR REPLACE FORCE EDITIONING VIEW DDL_AUDIT_LOG AS select * from DDL_AUDIT_LOG_T;
