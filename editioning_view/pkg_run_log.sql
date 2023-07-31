BEGIN deploy_utils.log_deploy_info('PKG_RUN_LOG','pkg_run_log.sql dheltzel'); END;
/

DROP VIEW PKG_RUN_LOG;
CREATE OR REPLACE FORCE EDITIONING VIEW PKG_RUN_LOG AS select * from PKG_RUN_LOG_T;
