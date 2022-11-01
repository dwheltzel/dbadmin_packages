-- create_schema.sql 
-- Author: dheltzel
-- Create Date 2014-01-03 

-- Create the user 
create user DBADMIN identified by "GDFHDF34-)" default tablespace USERS temporary tablespace TEMP profile DEFAULT;
-- Grant/Revoke system privileges 
grant unlimited tablespace to DBADMIN;
