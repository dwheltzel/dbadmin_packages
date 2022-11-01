BEGIN deploy_utils.log_deploy_info('PKG_RUN_LOG','pkg_run_log.sql dheltzel'); END;
/

CREATE OR REPLACE FORCE EDITIONING VIEW ADMIN.PKG_RUN_LOG (PACKAGE, REVISION, EDITION, SOURCE_FILE, REV_AUTHOR, REV_DATE, FIRST_LOAD_TS, FIRST_LOAD_USER, LAST_LOAD_TS, LAST_LOAD_USER) AS 
  select PACKAGE,REVISION,EDITION,SOURCE_FILE,REV_AUTHOR,REV_DATE,FIRST_LOAD_TS,FIRST_LOAD_USER,LAST_LOAD_TS,LAST_LOAD_USER from ADMIN.PKG_RUN_LOG_;
