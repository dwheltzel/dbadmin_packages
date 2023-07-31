-- create_schema.sql 
-- Author: dheltzel


create user %1 identified by "GDFHDF34-)";
grant connect,resource to %1;
grant unlimited tablespace to %1;
