BEGIN deploy_utils.log_deploy_info('DATA_AUDIT_LOG','data_audit_log.sql dheltzel'); END;
/

DROP VIEW DATA_AUDIT_LOG;
CREATE OR REPLACE FORCE EDITIONING VIEW DATA_AUDIT_LOG AS select * from DATA_AUDIT_LOG_T;
