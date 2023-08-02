CREATE OR REPLACE PACKAGE BODY AUDIT_PKG IS
  -- File audit_pkg_body.sql
  -- Author: dheltzel
  LC_SVN_ID VARCHAR2(200) := 'audit_pkg_body.sql dheltzel';

  LV_PROC_NAME ERR_LOG.PROC_NAME%TYPE;

  LV_COMMENT ERR_LOG.SOURCE_FILE%TYPE := 'Starting';

  PROCEDURE TEST_HARNESS_LOG_ERROR IS
  BEGIN
    LV_PROC_NAME := 'test_harness_log_error';
    LV_COMMENT   := 'No error - test only';
    LOG_ERROR(LC_SVN_ID,
              LV_PROC_NAME,
              LV_COMMENT,
              'No data to log',
              $$PLSQL_UNIT,
              $$PLSQL_LINE,
              SQLCODE,
              SQLERRM);
  END TEST_HARNESS_LOG_ERROR;

  PROCEDURE LOG_DETAILED_ERROR(P_SOURCE_FILE ERR_LOG.SOURCE_FILE%TYPE,
                               P_REVISION    ERR_LOG.REVISION%TYPE,
                               P_REV_AUTHOR  ERR_LOG.REV_AUTHOR%TYPE,
                               P_REV_DATE    ERR_LOG.REV_DATE%TYPE,
                               P_PROC_NAME   ERR_LOG.PROC_NAME%TYPE,
                               P_ERROR_LOC   ERR_LOG.ERROR_LOC%TYPE,
                               P_ERROR_DATA  ERR_LOG.ERROR_DATA%TYPE,
                               P_PLSQL_UNIT  ERR_LOG.PLSQL_UNIT%TYPE,
                               P_PLSQL_LINE  ERR_LOG.PLSQL_LINE%TYPE,
                               P_SQLCODE     ERR_LOG.SQLCODE%TYPE,
                               P_SQLERRM     ERR_LOG.SQLERRM%TYPE) IS
    PRAGMA AUTONOMOUS_TRANSACTION;
    V_SKIP_ERROR CUSTOM_EXCEPT_HANDLING.SKIP_ERR%TYPE;
  BEGIN
    SELECT MAX(SKIP_ERR)
      INTO V_SKIP_ERROR
      FROM CUSTOM_EXCEPT_HANDLING
     WHERE ERR_NUM = P_SQLCODE
       AND (PROCNAME = P_PROC_NAME OR PROCNAME = P_PLSQL_UNIT OR
           PROCNAME = 'All')
       AND SKIP_ERR = 'Y';
    IF (V_SKIP_ERROR IS NULL) THEN
      INSERT INTO ERR_LOG
        (LOG_DATE,
         USER_NAME,
         ERROR_TYPE,
         EDITION,
         PROC_NAME,
         ERROR_LOC,
         ERROR_DATA,
         SOURCE_FILE,
         REVISION,
         REV_AUTHOR,
         REV_DATE,
         PLSQL_UNIT,
         PLSQL_LINE,
         SQLCODE,
         SQLERRM)
      VALUES
        (SYSDATE,
         SYS_CONTEXT('USERENV', 'SESSION_USER'),
         'PLSQL',
         SYS_CONTEXT('USERENV', 'CURRENT_EDITION_NAME'),
         P_PROC_NAME,
         P_ERROR_LOC,
         P_ERROR_DATA,
         P_SOURCE_FILE,
         P_REVISION,
         P_REV_AUTHOR,
         P_REV_DATE,
         P_PLSQL_UNIT,
         P_PLSQL_LINE,
         P_SQLCODE,
         P_SQLERRM);
      COMMIT;
    END IF;
  END LOG_DETAILED_ERROR;

  PROCEDURE LOG_ERROR(P_SVN_ID     VARCHAR2,
                      P_PROC_NAME  ERR_LOG.PROC_NAME%TYPE,
                      P_ERROR_LOC  ERR_LOG.ERROR_LOC%TYPE,
                      P_ERROR_DATA ERR_LOG.ERROR_DATA%TYPE,
                      P_PLSQL_UNIT ERR_LOG.PLSQL_UNIT%TYPE,
                      P_PLSQL_LINE ERR_LOG.PLSQL_LINE%TYPE,
                      P_SQLCODE    ERR_LOG.SQLCODE%TYPE,
                      P_SQLERRM    ERR_LOG.SQLERRM%TYPE) IS
    L_SOURCE_FILE ERR_LOG.SOURCE_FILE%TYPE;
    L_REVISION    ERR_LOG.REVISION%TYPE;
    L_REV_AUTHOR  ERR_LOG.REV_AUTHOR%TYPE;
    L_REV_DATE    ERR_LOG.REV_DATE%TYPE;
    L_REMAINING   VARCHAR2(2000);
    L_LOC         PLS_INTEGER;
  BEGIN
    -- Parse the p_svn_id argument into parts to store in the table
    L_REMAINING := TRIM(LTRIM(P_SVN_ID, '$Id:'));
    -- source_file
    L_LOC         := INSTR(L_REMAINING, ' ', 1, 1);
    L_SOURCE_FILE := TRIM(SUBSTR(L_REMAINING, 1, L_LOC));
    L_REMAINING   := TRIM(SUBSTR(L_REMAINING, L_LOC + 1));
    -- revision
    L_LOC       := INSTR(L_REMAINING, ' ', 1, 1);
    L_REVISION  := TRIM(SUBSTR(L_REMAINING, 1, L_LOC));
    L_REMAINING := TRIM(SUBSTR(L_REMAINING, L_LOC + 1));
    -- l_rev_date
    L_LOC      := INSTR(L_REMAINING, ' ', 1, 2);
    L_REV_DATE := TRIM(SUBSTR(L_REMAINING, 1, L_LOC));
    -- rev_author
    L_REV_AUTHOR := TRIM(RTRIM(SUBSTR(L_REMAINING, L_LOC + 1), '$'));
    -- Call proc to log error
    LOG_DETAILED_ERROR(L_SOURCE_FILE,
                       L_REVISION,
                       L_REV_AUTHOR,
                       L_REV_DATE,
                       P_PROC_NAME,
                       P_ERROR_LOC,
                       P_ERROR_DATA,
                       P_PLSQL_UNIT,
                       P_PLSQL_LINE,
                       P_SQLCODE,
                       P_SQLERRM);
  END LOG_ERROR;

  PROCEDURE LOG_ACTION(P_APP_NAME    VARCHAR2,
                       P_ACTION_TYPE VARCHAR2,
                       P_LOG_COMMENT VARCHAR2) IS
    PRAGMA AUTONOMOUS_TRANSACTION;
  BEGIN
    INSERT INTO ACTION_AUDIT_LOG
      (LOG_DATE, USER_NAME, EDITION, APP_NAME, ACTION_TYPE, LOG_COMMENT)
    VALUES
      (SYSDATE,
       USER,
       SYS_CONTEXT('USERENV', 'CURRENT_EDITION_NAME'),
       P_APP_NAME,
       P_ACTION_TYPE,
       P_LOG_COMMENT);
    COMMIT;
  END LOG_ACTION;

  PROCEDURE LOG_DATA_CHANGE(P_APP_NAME      VARCHAR2,
                            P_OWNER         VARCHAR2,
                            P_TABLE_NAME    VARCHAR2,
                            P_ACTION_TYPE   VARCHAR2,
                            P_DML_TYPE      VARCHAR2,
                            P_RECS_AFFECTED INTEGER,
                            P_LOG_COMMENT   VARCHAR2) IS
    PRAGMA AUTONOMOUS_TRANSACTION;
  BEGIN
    INSERT INTO DATA_AUDIT_LOG
      (LOG_DATE,
       USER_NAME,
       EDITION,
       APP_NAME,
       TAB_OWNER,
       TAB_NAME,
       ACTION_TYPE,
       DML_TYPE,
       RECS_AFFECTED,
       LOG_COMMENT)
    VALUES
      (SYSDATE,
       USER,
       SYS_CONTEXT('USERENV', 'CURRENT_EDITION_NAME'),
       P_APP_NAME,
       P_OWNER,
       P_TABLE_NAME,
       P_ACTION_TYPE,
       P_DML_TYPE,
       P_RECS_AFFECTED,
       P_LOG_COMMENT);
    COMMIT;
  END LOG_DATA_CHANGE;

  PROCEDURE LOG_DDL_CHANGE(P_OBJECT_OWNER VARCHAR2,
                           P_OBJECT_NAME  VARCHAR2,
                           P_OBJECT_TYPE  VARCHAR2,
                           P_PARENT_NAME  VARCHAR2,
                           P_TICKET       VARCHAR2,
                           P_SQL_EXECUTED VARCHAR2,
                           P_MESSAGE      VARCHAR2,
                           P_SVN_ID       VARCHAR2) IS
    PRAGMA AUTONOMOUS_TRANSACTION;
    L_SOURCE_FILE  ERR_LOG.SOURCE_FILE%TYPE;
    L_REVISION     ERR_LOG.REVISION%TYPE;
    L_REV_AUTHOR   ERR_LOG.REV_AUTHOR%TYPE;
    L_REV_DATE     ERR_LOG.REV_DATE%TYPE;
    L_REMAINING    VARCHAR2(2000);
    L_LOC          PLS_INTEGER;
    L_ROLLBACK_DDL VARCHAR2(2000);
  BEGIN
    -- Parse the p_svn_id argument into parts to store in the table
    L_REMAINING := TRIM(LTRIM(P_SVN_ID, '$Id:'));
    -- source_file
    L_LOC         := INSTR(L_REMAINING, ' ', 1, 1);
    L_SOURCE_FILE := TRIM(SUBSTR(L_REMAINING, 1, L_LOC));
    L_REMAINING   := TRIM(SUBSTR(L_REMAINING, L_LOC + 1));
    -- revision
    L_LOC       := INSTR(L_REMAINING, ' ', 1, 1);
    L_REVISION  := TRIM(SUBSTR(L_REMAINING, 1, L_LOC));
    L_REMAINING := TRIM(SUBSTR(L_REMAINING, L_LOC + 1));
    -- l_rev_date
    L_LOC      := INSTR(L_REMAINING, ' ', 1, 2);
    L_REV_DATE := TRIM(SUBSTR(L_REMAINING, 1, L_LOC));
    -- rev_author
    L_REV_AUTHOR := TRIM(RTRIM(SUBSTR(L_REMAINING, L_LOC + 1), '$'));
    -- generate rollback DDL
    IF P_OBJECT_TYPE IN
       ('TABLE', 'SEQUENCE', 'JOB', 'CONSTRAINT', 'INDEX', 'COLUMN') THEN
      L_ROLLBACK_DDL := 'exec deploy_utils.drop_object(''' || P_TICKET ||
                        ''',''' || P_OBJECT_TYPE || ''',''' ||
                        P_OBJECT_OWNER || ''',''' || P_OBJECT_NAME || ''')';
    END IF;
    -- Insert this info into the table
    INSERT INTO DDL_AUDIT_LOG
      (OBJECT_OWNER,
       OBJECT_NAME,
       OBJECT_TYPE,
       PARENT_NAME,
       TICKET,
       SQL_EXECUTED,
       EDITION,
       SOURCE_FILE,
       REVISION,
       REV_AUTHOR,
       REV_DATE,
       MESSAGE,
       ROLLBACK_DDL)
    VALUES
      (P_OBJECT_OWNER,
       P_OBJECT_NAME,
       P_OBJECT_TYPE,
       P_PARENT_NAME,
       P_TICKET,
       P_SQL_EXECUTED,
       SYS_CONTEXT('USERENV', 'CURRENT_EDITION_NAME'),
       L_SOURCE_FILE,
       L_REVISION,
       L_REV_AUTHOR,
       L_REV_DATE,
       P_MESSAGE,
       L_ROLLBACK_DDL);
    COMMIT;
  END LOG_DDL_CHANGE;

  PROCEDURE LOG_PKG_INIT(P_PACKAGE VARCHAR2, P_SVN_ID VARCHAR2) IS
    PRAGMA AUTONOMOUS_TRANSACTION;
    L_SOURCE_FILE    ERR_LOG.SOURCE_FILE%TYPE;
    L_REVISION       ERR_LOG.REVISION%TYPE;
    L_REV_AUTHOR     ERR_LOG.REV_AUTHOR%TYPE;
    L_REV_DATE       ERR_LOG.REV_DATE%TYPE;
    L_REMAINING      VARCHAR2(2000);
    L_LOC            PLS_INTEGER;
    V_LAST_LOAD_DATE PKG_RUN_LOG.LAST_LOAD_DATE%TYPE;
  BEGIN
    -- check whether it has been at least an hour since we've updated this record
    SELECT MAX(LAST_LOAD_DATE)
      INTO V_LAST_LOAD_DATE
      FROM PKG_RUN_LOG
     WHERE PACKAGE = P_PACKAGE;
    IF (V_LAST_LOAD_DATE IS NULL OR
       V_LAST_LOAD_DATE < CURRENT_TIMESTAMP - INTERVAL '60' MINUTE) THEN
      -- Parse the p_svn_id argument into parts to store in the table
      L_REMAINING := TRIM(LTRIM(P_SVN_ID, '$Id:'));
      -- source_file
      L_LOC         := INSTR(L_REMAINING, ' ', 1, 1);
      L_SOURCE_FILE := TRIM(SUBSTR(L_REMAINING, 1, L_LOC));
      L_REMAINING   := TRIM(SUBSTR(L_REMAINING, L_LOC + 1));
      -- revision
      L_LOC       := INSTR(L_REMAINING, ' ', 1, 1);
      L_REVISION  := TRIM(SUBSTR(L_REMAINING, 1, L_LOC));
      L_REMAINING := TRIM(SUBSTR(L_REMAINING, L_LOC + 1));
      -- l_rev_date
      L_LOC      := INSTR(L_REMAINING, ' ', 1, 2);
      L_REV_DATE := TRIM(SUBSTR(L_REMAINING, 1, L_LOC));
      -- rev_author
      L_REV_AUTHOR := TRIM(RTRIM(SUBSTR(L_REMAINING, L_LOC + 1), '$'));
      -- Merge this info into the table
      MERGE INTO PKG_RUN_LOG A
      USING (SELECT P_PACKAGE PACKAGE,
                    L_REVISION REVISION,
                    SYS_CONTEXT('USERENV', 'CURRENT_EDITION_NAME') EDITION,
                    L_SOURCE_FILE SOURCE_FILE,
                    L_REV_DATE REV_DATE,
                    L_REV_AUTHOR REV_AUTHOR,
                    SYSDATE LAST_LOAD_DATE,
                    USER LAST_LOAD_USER
               FROM DUAL) B
      ON (A.PACKAGE = B.PACKAGE AND A.REVISION = B.REVISION AND A.EDITION = B.EDITION)
      WHEN NOT MATCHED THEN
        INSERT
          (PACKAGE,
           REVISION,
           EDITION,
           SOURCE_FILE,
           REV_DATE,
           REV_AUTHOR,
           LAST_LOAD_DATE,
           LAST_LOAD_USER)
        VALUES
          (P_PACKAGE,
           L_REVISION,
           SYS_CONTEXT('USERENV', 'CURRENT_EDITION_NAME'),
           L_SOURCE_FILE,
           L_REV_DATE,
           L_REV_AUTHOR,
           SYSDATE,
           USER)
      WHEN MATCHED THEN
        UPDATE
           SET A.SOURCE_FILE    = B.SOURCE_FILE,
               A.REV_DATE       = B.REV_DATE,
               A.REV_AUTHOR     = B.REV_AUTHOR,
               A.LAST_LOAD_DATE = B.LAST_LOAD_DATE,
               A.LAST_LOAD_USER = B.LAST_LOAD_USER;
      COMMIT;
    END IF;
  END LOG_PKG_INIT;

BEGIN
  LOG_PKG_INIT($$PLSQL_UNIT, LC_SVN_ID);
END AUDIT_PKG;
/
