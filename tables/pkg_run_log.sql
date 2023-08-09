-- File pkg_run_log.sql
-- Author: dheltzel

CREATE TABLE PKG_RUN_LOG_T
(
  OWNER            VARCHAR2(30) NOT NULL,
  PACKAGE          VARCHAR2(30) NOT NULL,
  REVISION         VARCHAR2(30) NOT NULL,
  EDITION          VARCHAR2(30) DEFAULT ON NULL 'ORA$BASE' NOT NULL,
  SOURCE_FILE      VARCHAR2(30),
  REV_AUTHOR       VARCHAR2(30),
  REV_DATE         VARCHAR2(30),
  FIRST_LOAD_DATE  DATE,
  FIRST_LOAD_USER  VARCHAR2(30),
  LAST_LOAD_DATE   DATE,
  LAST_LOAD_USER   VARCHAR2(30)
);

COMMENT ON TABLE PKG_RUN_LOG_T IS 'Log of times that a particular package version was running';
COMMENT ON COLUMN PKG_RUN_LOG_T.OWNER IS 'Owner of the package';
COMMENT ON COLUMN PKG_RUN_LOG_T.PACKAGE IS 'Package name';
COMMENT ON COLUMN PKG_RUN_LOG_T.REVISION IS 'Package revision';
COMMENT ON COLUMN PKG_RUN_LOG_T.EDITION IS 'Edition this package was run in';
COMMENT ON COLUMN PKG_RUN_LOG_T.SOURCE_FILE IS 'Package source file';
COMMENT ON COLUMN PKG_RUN_LOG_T.REV_AUTHOR IS 'Author of this revision';
COMMENT ON COLUMN PKG_RUN_LOG_T.REV_DATE IS 'Date of this revision';
COMMENT ON COLUMN PKG_RUN_LOG_T.FIRST_LOAD_DATE IS 'The first time this package was loaded into the shared pool';
COMMENT ON COLUMN PKG_RUN_LOG_T.FIRST_LOAD_USER IS 'The first user who loaded this package into the shared pool';
COMMENT ON COLUMN PKG_RUN_LOG_T.LAST_LOAD_DATE IS 'The last time this package was loaded into the shared pool';
COMMENT ON COLUMN PKG_RUN_LOG_T.LAST_LOAD_USER IS 'The last user who loaded this package into the shared pool';

ALTER TABLE PKG_RUN_LOG_T add constraint PKG_RUN_LOG_PK primary key (OWNER, PACKAGE, REVISION, EDITION);

CREATE OR REPLACE VIEW PKG_RUN_LOG AS select * from PKG_RUN_LOG_T;
