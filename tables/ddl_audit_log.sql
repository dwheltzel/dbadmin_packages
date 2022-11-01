-- File ddl_audit_log.sql
-- Author: dheltzel
-- Create Date: 2014-03-26

create table DDL_AUDIT_LOG
(
  TIMESTAMP    TIMESTAMP(6) default SYSTIMESTAMP not null,
  OBJECT_OWNER VARCHAR2(30),
  OBJECT_NAME  VARCHAR2(30),
  OBJECT_TYPE  VARCHAR2(30),
  PARENT_NAME  VARCHAR2(30),
  TICKET       VARCHAR2(30),
  SQL_EXECUTED VARCHAR2(4000),
  USER_NAME    VARCHAR2(30) default USER not null,
  EDITION      VARCHAR2(30),
  SOURCE_FILE  VARCHAR2(30),
  REVISION     VARCHAR2(30),
  REV_AUTHOR   VARCHAR2(30),
  REV_DATE     VARCHAR2(30),
  SQLCODE      VARCHAR2(30),
  MESSAGE      VARCHAR2(4000),
  ROLLBACK_DDL VARCHAR2(4000)
);

comment on table DDL_AUDIT_LOG is 'DDL Changes';
comment on column DDL_AUDIT_LOG.TIMESTAMP is 'Time that DDL change was executed';
comment on column DDL_AUDIT_LOG.PARENT_NAME is 'Name of the objects parent - if applicable';
comment on column DDL_AUDIT_LOG.TICKET is 'JIRA ticket associated with this change';
comment on column DDL_AUDIT_LOG.SQL_EXECUTED is 'Actual SQL that was run for this DDL change';
comment on column DDL_AUDIT_LOG.EDITION is 'Name of the edition the executing session is using';
comment on column DDL_AUDIT_LOG.SQLCODE is 'Value of SQLCODE'; 
comment on column DDL_AUDIT_LOG.USER_NAME is 'Login name of the session';
comment on column DDL_AUDIT_LOG.SOURCE_FILE is 'URL of the source in SVN';
comment on column DDL_AUDIT_LOG.REVISION is 'SVN Revision info';
comment on column DDL_AUDIT_LOG.REV_AUTHOR is 'Author of the last change';
comment on column DDL_AUDIT_LOG.REV_DATE is 'Time of the last change';
comment on column DDL_AUDIT_LOG.MESSAGE is 'Comment - ex. value of SQLERRM';
comment on column DDL_AUDIT_LOG.ROLLBACK_DDL is 'DDL to rollback this change';

create index DDL_AUDIT_LOG_TS on DDL_AUDIT_LOG (TIMESTAMP);
create index DDL_AUDIT_LOG_TKT on DDL_AUDIT_LOG (TICKET);

