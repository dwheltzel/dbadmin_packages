-- File custom_except_handling.sql
-- Author: dheltzel

create table CUSTOM_EXCEPT_HANDLING_T
(
  ERR_NUM INTEGER NOT NULL,
  PROCNAME VARCHAR2(30) NOT NULL,
  SKIP_ERR VARCHAR2(1),
  RULE_COMMENT VARCHAR2(100),
  LOG_DATE DATE default sysdate,
  USER_NAME VARCHAR2(30) default USER
);

comment on table CUSTOM_EXCEPT_HANDLING_T is 'Dynamic management of exception handling';

CREATE OR REPLACE VIEW CUSTOM_EXCEPT_HANDLING AS select * from CUSTOM_EXCEPT_HANDLING_T;
