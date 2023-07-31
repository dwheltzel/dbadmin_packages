BEGIN deploy_utils.log_deploy_info('ACTION_AUDIT_LOG','action_audit_log.sql dheltzel'); END;
/

DROP VIEW ACTION_AUDIT_LOG;
CREATE OR REPLACE FORCE EDITIONING VIEW ACTION_AUDIT_LOG AS select * from ACTION_AUDIT_LOG_T;
