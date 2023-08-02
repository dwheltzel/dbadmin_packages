-- File err_log.sql
-- Author: dheltzel

create table ERR_LOG_T
(
  LOG_DATE     DATE DEFAULT SYSDATE NOT NULL,
  USER_NAME    VARCHAR2(30) DEFAULT USER NOT NULL,
  ERROR_TYPE   VARCHAR2(30) DEFAULT 'PLSQL',
  EDITION      VARCHAR2(30),
  PROC_NAME    VARCHAR2(30),
  ERROR_LOC    VARCHAR2(2000),
  ERROR_DATA   VARCHAR2(2000),
  SOURCE_FILE  VARCHAR2(30),
  REVISION     VARCHAR2(30),
  REV_AUTHOR   VARCHAR2(30),
  REV_DATE     VARCHAR2(30),
  PLSQL_UNIT   VARCHAR2(30),
  PLSQL_LINE   INTEGER,
  SQLCODE      VARCHAR2(30),
  SQLERRM      VARCHAR2(4000)
)
PARTITION BY RANGE(LOG_DATE) INTERVAL(numtoyminterval(1,'MONTH')) 
(
 PARTITION error_log_2023_10 VALUES LESS THAN (to_date('2023-11-01','YYYY-MM-DD')) 
);

comment on table ERR_LOG_T is 'Repository of database application errors';
comment on column ERR_LOG_T.LOG_DATE is 'Time that error occured';
comment on column ERR_LOG_T.USER_NAME is 'Login name of the session - sys_context(''USERENV'', ''SESSION_USER'')';
comment on column ERR_LOG_T.ERROR_TYPE is 'Type of error - default to PL/SQL code error';
comment on column ERR_LOG_T.PROC_NAME is 'Name of the procedure being invoked';
comment on column ERR_LOG_T.ERROR_LOC is 'Comment set in code to help locate code section with error';
comment on column ERR_LOG_T.ERROR_DATA is 'Data values optionally sent to help debug error';
comment on column ERR_LOG_T.SQLCODE is 'Value of SQLCODE';
comment on column ERR_LOG_T.SQLERRM is 'Value of SQLERRM';

create index ERR_LOG_DATE on ERR_LOG_T (LOG_DATE);

CREATE OR REPLACE VIEW ERR_LOG AS select * from ERR_LOG_T;
