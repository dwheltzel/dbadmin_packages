-- File data_audit_log.sql
-- Author: dheltzel

create table DATA_AUDIT_LOG_T
(
  LOG_DATE       DATE DEFAULT ON NULL SYSDATE NOT NULL,
  USER_NAME      VARCHAR2(30) DEFAULT ON NULL USER NOT NULL,
  EDITION        VARCHAR2(30),
  APP_NAME       VARCHAR2(30) not null,
  TAB_OWNER      VARCHAR2(30) not null,
  TAB_NAME       VARCHAR2(30) not null,
  ACTION_TYPE    VARCHAR2(30) not null,
  DML_TYPE       VARCHAR2(30) not null,
  RECS_AFFECTED  INTEGER not null,
  LOG_COMMENT    VARCHAR2(2000)
)
PARTITION BY RANGE(LOG_DATE) INTERVAL(numtoyminterval(1,'MONTH')) 
(
 PARTITION data_audit_log_2023_10 VALUES LESS THAN (to_date('2023-11-01','YYYY-MM-DD')) 
);

comment on table DATA_AUDIT_LOG_T is 'Auditable DML by any application';
comment on column DATA_AUDIT_LOG_T.LOG_DATE is 'Time that DML occured';
comment on column DATA_AUDIT_LOG_T.USER_NAME is 'Login name of the session - sys_context(''USERENV'', ''SESSION_USER'')';

create index DATA_AUDIT_LOG_DATE on DATA_AUDIT_LOG_T (LOG_DATE);

CREATE OR REPLACE VIEW DATA_AUDIT_LOG AS select * from DATA_AUDIT_LOG_T;
