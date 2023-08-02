-- File action_audit_log.sql
-- Author: dheltzel

create table ACTION_AUDIT_LOG_T
(
  LOG_DATE       DATE DEFAULT ON NULL SYSDATE NOT NULL,
  USER_NAME      VARCHAR2(30) DEFAULT ON NULL USER NOT NULL,
  EDITION        VARCHAR2(30),
  APP_NAME       VARCHAR2(30) NOT NULL,
  ACTION_TYPE    VARCHAR2(30) NOT NULL,
  LOG_COMMENT    VARCHAR2(2000)
)
PARTITION BY RANGE(LOG_DATE) INTERVAL(numtoyminterval(1,'MONTH')) 
(
 PARTITION action_audit_log_2023_10 VALUES LESS THAN (to_date('2023-11-01','YYYY-MM-DD')) 
);

comment on table ACTION_AUDIT_LOG_T is 'Auditable actions by any application';
comment on column ACTION_AUDIT_LOG_T.LOG_DATE is 'Time that action occured';
comment on column ACTION_AUDIT_LOG_T.USER_NAME is 'Login name of the session';
comment on column ACTION_AUDIT_LOG_T.EDITION is 'Name of the edition in use, if applicable';
comment on column ACTION_AUDIT_LOG_T.APP_NAME is 'Name of the application';
comment on column ACTION_AUDIT_LOG_T.ACTION_TYPE is 'User defined type of action';
comment on column ACTION_AUDIT_LOG_T.LOG_COMMENT is 'Description of the action';

create index ACTION_AUDIT_LOG_DATE on ACTION_AUDIT_LOG_T (LOG_DATE);
create index ACTION_AUDIT_LOG_TYPE_APP on ACTION_AUDIT_LOG_T (ACTION_TYPE,APP_NAME,LOG_DATE) compress 2;

CREATE OR REPLACE VIEW ACTION_AUDIT_LOG AS select * from ACTION_AUDIT_LOG_T;
