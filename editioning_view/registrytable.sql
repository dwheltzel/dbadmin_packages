BEGIN deploy_utils.log_deploy_info('REGISTRYTABLE','registrytable.sql dheltzel'); END;
/

DROP VIEW REGISTRYTABLE;
CREATE OR REPLACE FORCE EDITIONING VIEW REGISTRYTABLE AS select * from REGISTRYTABLE_T;
