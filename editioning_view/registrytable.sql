BEGIN admin.deploy_utils.log_deploy_info('REGISTRYTABLE','$Id: registrytable.sql 1419 2013-11-20 20:49:39Z dheltzel $'); END;
/

CREATE OR REPLACE FORCE EDITIONING VIEW ADMIN.REGISTRYTABLE (NAMESPACE, ENVIR, NAME, IMMUTABLE, VALUE, CREATE_TS, CREATE_USER, UPDATE_TS, UPDATE_USER) AS 
 select NAMESPACE, ENVIR, NAME, IMMUTABLE, VALUE, CREATE_TS, CREATE_USER, UPDATE_TS, UPDATE_USER from ADMIN.REGISTRYTABLE_;
