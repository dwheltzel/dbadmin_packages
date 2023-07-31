-- File ddl_audit_log.sql
-- Author: dheltzel

create table DDL_AUDIT_LOG_T
(
  LOG_DATE     DATE default SYSDATE not null,
  OBJECT_OWNER VARCHAR2(30) not null,
  OBJECT_NAME  VARCHAR2(30) not null,
  OBJECT_TYPE  VARCHAR2(30) not null,
  PARENT_NAME  VARCHAR2(30),
  TICKET       VARCHAR2(30),
  SQL_EXECUTED VARCHAR2(4000) not null,
  USER_NAME    VARCHAR2(30) default USER not null,
  EDITION      VARCHAR2(30),
  SOURCE_FILE  VARCHAR2(30),
  REVISION     VARCHAR2(30),
  REV_AUTHOR   VARCHAR2(30),
  REV_DATE     VARCHAR2(30),
  SQLCODE      VARCHAR2(30),
  MESSAGE      VARCHAR2(4000),
  ROLLBACK_DDL VARCHAR2(4000)
)
PARTITION BY RANGE(LOG_DATE) INTERVAL(numtoyminterval(1,'MONTH')) 
(
 PARTITION ddl_audit_log_2023_10 VALUES LESS THAN (to_date('2023-11-01','YYYY-MM-DD')) 
);

comment on table DDL_AUDIT_LOG_T is 'DDL Changes';
comment on column DDL_AUDIT_LOG_T.LOG_DATE is 'Time that DDL change was executed';
comment on column DDL_AUDIT_LOG_T.PARENT_NAME is 'Name of the objects parent - if applicable';
comment on column DDL_AUDIT_LOG_T.TICKET is 'JIRA ticket associated with this change';
comment on column DDL_AUDIT_LOG_T.SQL_EXECUTED is 'Actual SQL that was run for this DDL change';
comment on column DDL_AUDIT_LOG_T.EDITION is 'Name of the edition the executing session is using';
comment on column DDL_AUDIT_LOG_T.SQLCODE is 'Value of SQLCODE'; 
comment on column DDL_AUDIT_LOG_T.USER_NAME is 'Login name of the session';
comment on column DDL_AUDIT_LOG_T.SOURCE_FILE is 'URL of the source in SVN';
comment on column DDL_AUDIT_LOG_T.REVISION is 'SVN Revision info';
comment on column DDL_AUDIT_LOG_T.REV_AUTHOR is 'Author of the last change';
comment on column DDL_AUDIT_LOG_T.REV_DATE is 'Time of the last change';
comment on column DDL_AUDIT_LOG_T.MESSAGE is 'Comment - ex. value of SQLERRM';
comment on column DDL_AUDIT_LOG_T.ROLLBACK_DDL is 'DDL to rollback this change';

create index DDL_AUDIT_LOG_DATE on DDL_AUDIT_LOG_T (LOG_DATE);
create index DDL_AUDIT_LOG_TKT on DDL_AUDIT_LOG_T (TICKET);

CREATE OR REPLACE VIEW DDL_AUDIT_LOG AS select * from DDL_AUDIT_LOG_T;
