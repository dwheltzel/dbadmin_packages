-- Verify that the dbadmin.deploy_utils package is installed correctly
--
-- File $Id: VerifyDeployUtils.sql 4160 2014-04-22 19:28:05Z dheltzel $
-- Modified $Author: dheltzel $ 
-- Date $Date: 2014-04-22 15:28:05 -0400 (Tue, 22 Apr 2014) $
-- Revision $Revision: 4160 $
--
SET serverout ON SIZE UNLIMITED
SET feed OFF
SET lines 150
SET pages 0
SET trimspool ON
COL spool_name FOR a40 new_value spool_name
SELECT 'VerifyDeployUtils_'||db_unique_name||'_'||to_char(SYSDATE,'YYMMDDHH24MI')||'.sql' spool_name from v$database;
SPOOL &spool_name
BEGIN dbadmin.deploy_utils.pkg_info; END;
/
SPOOL OFF
EXIT
