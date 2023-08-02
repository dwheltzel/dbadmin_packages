-- File pkg_run_log.sql
-- Author: dheltzel

create table PKG_RUN_LOG_T
(
  OWNER            VARCHAR2(30) DEFAULT ON NULL USER NOT NULL,
  PACKAGE          VARCHAR2(30) NOT NULL,
  REVISION         VARCHAR2(30),
  EDITION          VARCHAR2(30),
  SOURCE_FILE      VARCHAR2(30),
  REV_AUTHOR       VARCHAR2(30),
  REV_DATE         VARCHAR2(30),
  FIRST_LOAD_DATE  DATE,
  FIRST_LOAD_USER  VARCHAR2(30),
  LAST_LOAD_DATE   DATE,
  LAST_LOAD_USER   VARCHAR2(30)
);

comment on table PKG_RUN_LOG_T is 'Log of times that a particular package version was running';

CREATE OR REPLACE VIEW PKG_RUN_LOG AS select * from PKG_RUN_LOG_T;
