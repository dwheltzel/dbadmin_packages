BEGIN admin.deploy_utils.log_deploy_info('CUSTOM_EXCEPT_HANDLING','$Id: custom_except_handling.sql 1419 2013-11-20 20:49:39Z dheltzel $'); END;
/

  CREATE OR REPLACE FORCE EDITIONING VIEW ADMIN.CUSTOM_EXCEPT_HANDLING (ERR_NUM, PROCNAME, SKIP_ERR, RULE_COMMENT, LOG_TIMESTAMP, USER_NAME) AS 
  select ERR_NUM,PROCNAME,SKIP_ERR,RULE_COMMENT,LOG_TIMESTAMP,USER_NAME from ADMIN.CUSTOM_EXCEPT_HANDLING_;