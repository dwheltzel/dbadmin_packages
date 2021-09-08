-- File $Id: action_audit_log.sql 2002 2014-01-03 20:55:45Z dheltzel $
-- Modified $Author: dheltzel $ 
-- Date $Date: 2014-01-03 15:55:45 -0500 (Fri, 03 Jan 2014) $
-- Revision $Revision: 2002 $

create table DBADMIN.ACTION_AUDIT_LOG
(
  LOG_TIMESTAMP  TIMESTAMP(6),
  USER_NAME      VARCHAR2(30),
  EDITION        VARCHAR2(30),
  APP_NAME       VARCHAR2(30),
  ACTION_TYPE    VARCHAR2(30),
  LOG_COMMENT    VARCHAR2(2000)
);

comment on table DBADMIN.ACTION_AUDIT_LOG is 'Auditable actions by any application';
comment on column DBADMIN.ACTION_AUDIT_LOG.LOG_TIMESTAMP is 'Time that action occured';
comment on column DBADMIN.ACTION_AUDIT_LOG.USER_NAME is 'Login name of the session - sys_context(''USERENV'', ''SESSION_USER'')';

create index DBADMIN.ACTION_AUDIT_LOG_TS on DBADMIN.ACTION_AUDIT_LOG (LOG_TIMESTAMP);
