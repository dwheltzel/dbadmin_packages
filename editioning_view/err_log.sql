BEGIN deploy_utils.log_deploy_info('ERR_LOG','err_log.sql dheltzel'); END;
/

DROP VIEW ERR_LOG;
CREATE OR REPLACE FORCE EDITIONING VIEW ERR_LOG AS select * from ERR_LOG_T;
