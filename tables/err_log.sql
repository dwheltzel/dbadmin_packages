-- File $Id: err_log.sql 2091 2014-01-08 16:38:37Z dheltzel $
-- Modified $Author: dheltzel $ 
-- Date $Date: 2014-01-08 11:38:37 -0500 (Wed, 08 Jan 2014) $
-- Revision $Revision: 2091 $

create table DBADMIN.ERR_LOG
(
  TIMESTAMP    TIMESTAMP(6),
  USER_NAME    VARCHAR2(30),
  ERROR_TYPE   VARCHAR2(30) default 'PLSQL',
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
);

comment on table DBADMIN.ERR_LOG is 'Repository of database application errors';
comment on column DBADMIN.ERR_LOG.TIMESTAMP is 'Time that error occured';
comment on column DBADMIN.ERR_LOG.USER_NAME is 'Login name of the session - sys_context(''USERENV'', ''SESSION_USER'')';
comment on column DBADMIN.ERR_LOG.ERROR_TYPE is 'Type of error - default to PL/SQL code error';
comment on column DBADMIN.ERR_LOG.PROC_NAME is 'Name of the procedure being invoked';
comment on column DBADMIN.ERR_LOG.ERROR_LOC is 'Comment set in code to help locate code section with error';
comment on column DBADMIN.ERR_LOG.ERROR_DATA is 'Data values optionally sent to help debug error';
comment on column DBADMIN.ERR_LOG.SQLCODE is 'Value of SQLCODE';
comment on column DBADMIN.ERR_LOG.SQLERRM is 'Value of SQLERRM';

create index DBADMIN.ERR_LOG_TS on DBADMIN.ERR_LOG (TIMESTAMP);
