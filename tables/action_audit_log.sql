-- File action_audit_log.sql
-- Author: dheltzel
-- Create Date: 2014-01-03

create table ACTION_AUDIT_LOG
(
  LOG_TIMESTAMP  TIMESTAMP(6),
  USER_NAME      VARCHAR2(30),
  EDITION        VARCHAR2(30),
  APP_NAME       VARCHAR2(30),
  ACTION_TYPE    VARCHAR2(30),
  LOG_COMMENT    VARCHAR2(2000)
);

comment on table ACTION_AUDIT_LOG is 'Auditable actions by any application';
comment on column ACTION_AUDIT_LOG.LOG_TIMESTAMP is 'Time that action occured';
comment on column ACTION_AUDIT_LOG.USER_NAME is 'Login name of the session - sys_context(''USERENV'', ''SESSION_USER'')';

create index ACTION_AUDIT_LOG_TS on ACTION_AUDIT_LOG (LOG_TIMESTAMP);
