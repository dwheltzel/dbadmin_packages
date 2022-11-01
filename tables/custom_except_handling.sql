-- File custom_except_handling.sql
-- Author: dheltzel
-- Create Date: 2014-01-03

create table CUSTOM_EXCEPT_HANDLING
(
  ERR_NUM INTEGER NOT NULL,
  PROCNAME VARCHAR2(30) NOT NULL,
  SKIP_ERR VARCHAR2(1),
  RULE_COMMENT VARCHAR2(100),
  LOG_TIMESTAMP TIMESTAMP(6) default sysdate,
  USER_NAME VARCHAR2(30) default USER
);

comment on table CUSTOM_EXCEPT_HANDLING is 'Dynamic management of exception handling';

