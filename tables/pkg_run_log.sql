-- File pkg_run_log.sql
-- Author: dheltzel
-- Create Date: 2014-01-03

create table PKG_RUN_LOG
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

comment on table PKG_RUN_LOG is 'Log of times that a particular package version was running';

