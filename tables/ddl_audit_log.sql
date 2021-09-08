-- File $Id: ddl_audit_log.sql 3503 2014-03-26 15:37:05Z dheltzel $
-- Modified $Author: dheltzel $ 
-- Date $Date: 2014-03-26 11:37:05 -0400 (Wed, 26 Mar 2014) $
-- Revision $Revision: 3503 $

create table DBADMIN.DDL_AUDIT_LOG
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

comment on table DBADMIN.DDL_AUDIT_LOG is 'DDL Changes';
comment on column DBADMIN.DDL_AUDIT_LOG.TIMESTAMP is 'Time that DDL change was executed';
comment on column DBADMIN.DDL_AUDIT_LOG.PARENT_NAME is 'Name of the objects parent - if applicable';
comment on column DBADMIN.DDL_AUDIT_LOG.TICKET is 'JIRA ticket associated with this change';
comment on column DBADMIN.DDL_AUDIT_LOG.SQL_EXECUTED is 'Actual SQL that was run for this DDL change';
comment on column DBADMIN.DDL_AUDIT_LOG.EDITION is 'Name of the edition the executing session is using';
comment on column DBADMIN.DDL_AUDIT_LOG.SQLCODE is 'Value of SQLCODE'; 
comment on column DBADMIN.DDL_AUDIT_LOG.USER_NAME is 'Login name of the session';
comment on column DBADMIN.DDL_AUDIT_LOG.SOURCE_FILE is 'URL of the source in SVN';
comment on column DBADMIN.DDL_AUDIT_LOG.REVISION is 'SVN Revision info';
comment on column DBADMIN.DDL_AUDIT_LOG.REV_AUTHOR is 'Author of the last change';
comment on column DBADMIN.DDL_AUDIT_LOG.REV_DATE is 'Time of the last change';
comment on column DBADMIN.DDL_AUDIT_LOG.MESSAGE is 'Comment - ex. value of SQLERRM';
comment on column DBADMIN.DDL_AUDIT_LOG.ROLLBACK_DDL is 'DDL to rollback this change';

create index DBADMIN.DDL_AUDIT_LOG_TS on DBADMIN.DDL_AUDIT_LOG (TIMESTAMP);
create index DBADMIN.DDL_AUDIT_LOG_TKT on DBADMIN.DDL_AUDIT_LOG (TICKET);

