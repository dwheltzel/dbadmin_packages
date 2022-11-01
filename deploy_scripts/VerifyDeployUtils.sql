-- Verify that the deploy_utils package is installed correctly
--
-- VerifyDeployUtils.sql
-- Author: dheltzel
-- Create Date 2014-04-22

SET serverout ON SIZE UNLIMITED
SET feed OFF
SET lines 150
SET pages 0
SET trimspool ON
COL spool_name FOR a40 new_value spool_name
SELECT 'VerifyDeployUtils_'||db_unique_name||'_'||to_char(SYSDATE,'YYMMDDHH24MI')||'.sql' spool_name from v$database;
SPOOL /home/oracle/logs/&spool_name
BEGIN deploy_utils.pkg_info; END;
/
SPOOL OFF
EXIT
