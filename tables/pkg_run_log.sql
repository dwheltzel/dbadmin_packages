-- File $Id: pkg_run_log.sql 2002 2014-01-03 20:55:45Z dheltzel $
-- Modified $Author: dheltzel $ 
-- Date $Date: 2014-01-03 15:55:45 -0500 (Fri, 03 Jan 2014) $
-- Revision $Revision: 2002 $

create table DBADMIN.PKG_RUN_LOG
(
  PACKAGE          VARCHAR2(30),
  REVISION         VARCHAR2(30),
  EDITION          VARCHAR2(30),
  SOURCE_FILE      VARCHAR2(30),
  REV_AUTHOR       VARCHAR2(30),
  REV_DATE         VARCHAR2(30),
  FIRST_LOAD_TS    TIMESTAMP(6),
  FIRST_LOAD_USER  VARCHAR2(30),
  LAST_LOAD_TS     TIMESTAMP(6),
  LAST_LOAD_USER   VARCHAR2(30)
);

comment on table DBADMIN.PKG_RUN_LOG is 'Log of itmes that a particular package version was running';

