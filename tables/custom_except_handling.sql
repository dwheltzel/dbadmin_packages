-- File $Id: custom_except_handling.sql 2002 2014-01-03 20:55:45Z dheltzel $
-- Modified $Author: dheltzel $ 
-- Date $Date: 2014-01-03 15:55:45 -0500 (Fri, 03 Jan 2014) $
-- Revision $Revision: 2002 $

create table DBADMIN.CUSTOM_EXCEPT_HANDLING
(
  ERR_NUM INTEGER NOT NULL,
  PROCNAME VARCHAR2(30) NOT NULL,
  SKIP_ERR VARCHAR2(1),
  RULE_COMMENT VARCHAR2(100),
  LOG_TIMESTAMP TIMESTAMP(6) default sysdate,
  USER_NAME VARCHAR2(30) default USER
);

comment on table DBADMIN.CUSTOM_EXCEPT_HANDLING is 'Dynamic management of exception handling';

