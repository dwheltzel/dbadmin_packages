-- File data_audit_log.sql
-- Author: dheltzel
-- Create Date: 2014-01-03

create table DATA_AUDIT_LOG
(
  LOG_TIMESTAMP  TIMESTAMP(6),
  USER_NAME      VARCHAR2(30),
  EDITION        VARCHAR2(30),
  APP_NAME       VARCHAR2(30),
  TAB_OWNER      VARCHAR2(30),
  TAB_NAME       VARCHAR2(30),
  ACTION_TYPE    VARCHAR2(30),
  DML_TYPE       VARCHAR2(30),
  RECS_AFFECTED  INTEGER,
  LOG_COMMENT    VARCHAR2(2000)
);

comment on table DATA_AUDIT_LOG is 'Auditable DML by any application';
comment on column DATA_AUDIT_LOG.LOG_TIMESTAMP is 'Time that DML occured';
comment on column DATA_AUDIT_LOG.USER_NAME is 'Login name of the session - sys_context(''USERENV'', ''SESSION_USER'')';

create index DATA_AUDIT_LOG_TS on DATA_AUDIT_LOG (LOG_TIMESTAMP);
