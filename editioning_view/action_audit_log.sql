BEGIN deploy_utils.log_deploy_info('ACTION_AUDIT_LOG','action_audit_log.sql dheltzel'); END;
/

CREATE OR REPLACE FORCE EDITIONING VIEW ADMIN.ACTION_AUDIT_LOG (LOG_TIMESTAMP, USER_NAME, EDITION, APP_NAME, ACTION_TYPE, LOG_COMMENT) AS 
  select LOG_TIMESTAMP,USER_NAME,EDITION,APP_NAME,ACTION_TYPE,LOG_COMMENT from ADMIN.ACTION_AUDIT_LOG_;
