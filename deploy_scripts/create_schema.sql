-- File $Id: create_schema.sql 2002 2014-01-03 20:55:45Z dheltzel $
-- Modified $Author: dheltzel $ 
-- Date $Date: 2014-01-03 15:55:45 -0500 (Fri, 03 Jan 2014) $
-- Revision $Revision: 2002 $

-- Create the user 
create user DBADMIN identified by "GDFHDF34-)" default tablespace USERS temporary tablespace TEMP profile DEFAULT;
-- Grant/Revoke system privileges 
grant unlimited tablespace to DBADMIN;
