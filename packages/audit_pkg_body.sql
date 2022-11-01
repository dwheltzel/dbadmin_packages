SET DEFINE OFF

CREATE OR REPLACE PACKAGE BODY audit_pkg IS
  -- File audit_pkg_body.sql
  -- Author: dheltzel
  -- Create Date 2014-03-26
  lc_svn_id VARCHAR2(200) := 'audit_pkg_body.sql dheltzel';

  lv_proc_name err_log.proc_name%TYPE;

  lv_comment err_log.source_file%TYPE := 'Starting';

  PROCEDURE test_harness_log_error IS
  BEGIN
    lv_proc_name := 'test_harness_log_error';
    lv_comment   := 'No error - test only';
    log_error(lc_svn_id, lv_proc_name, lv_comment, 'No data to log', $$PLSQL_UNIT, $$PLSQL_LINE, SQLCODE, SQLERRM);
  END test_harness_log_error;

  PROCEDURE log_detailed_error(p_source_file err_log.source_file%TYPE,
                               p_revision    err_log.revision%TYPE,
                               p_rev_author  err_log.rev_author%TYPE,
                               p_rev_date    err_log.rev_date%TYPE,
                               p_proc_name   err_log.proc_name%TYPE,
                               p_error_loc   err_log.error_loc%TYPE,
                               p_error_data  err_log.error_data%TYPE,
                               p_plsql_unit  err_log.plsql_unit%TYPE,
                               p_plsql_line  err_log.plsql_line%TYPE,
                               p_sqlcode     err_log.sqlcode%TYPE,
                               p_sqlerrm     err_log.sqlerrm%TYPE) IS
    PRAGMA AUTONOMOUS_TRANSACTION;
    v_skip_error custom_except_handling.skip_err%TYPE;
  BEGIN
    SELECT MAX(skip_err)
      INTO v_skip_error
      FROM custom_except_handling
     WHERE err_num = p_sqlcode AND
           (procname = p_proc_name OR procname = p_plsql_unit OR procname = 'All') AND
           skip_err = 'Y';
    IF (v_skip_error IS NULL) THEN
      INSERT INTO err_log
        (TIMESTAMP,
         user_name,
         error_type,
         edition,
         proc_name,
         error_loc,
         error_data,
         source_file,
         revision,
         rev_author,
         rev_date,
         plsql_unit,
         plsql_line,
         SQLCODE,
         SQLERRM)
      VALUES
        (systimestamp,
         sys_context('USERENV', 'SESSION_USER'),
         'PLSQL',
         sys_context('USERENV', 'CURRENT_EDITION_NAME'),
         p_proc_name,
         p_error_loc,
         p_error_data,
         p_source_file,
         p_revision,
         p_rev_author,
         p_rev_date,
         p_plsql_unit,
         p_plsql_line,
         p_sqlcode,
         p_sqlerrm);
      COMMIT;
    END IF;
  END log_detailed_error;

  PROCEDURE log_error(p_svn_id     VARCHAR2,
                      p_proc_name  err_log.proc_name%TYPE,
                      p_error_loc  err_log.error_loc%TYPE,
                      p_error_data err_log.error_data%TYPE,
                      p_plsql_unit err_log.plsql_unit%TYPE,
                      p_plsql_line err_log.plsql_line%TYPE,
                      p_sqlcode    err_log.sqlcode%TYPE,
                      p_sqlerrm    err_log.sqlerrm%TYPE) IS
    l_source_file err_log.source_file%TYPE;
    l_revision    err_log.revision%TYPE;
    l_rev_author  err_log.rev_author%TYPE;
    l_rev_date    err_log.rev_date%TYPE;
    l_remaining   VARCHAR2(2000);
    l_loc         PLS_INTEGER;
  BEGIN
    -- Parse the p_svn_id argument into parts to store in the table
    l_remaining := TRIM(ltrim(p_svn_id, '$Id:'));
    -- source_file
    l_loc         := instr(l_remaining, ' ', 1, 1);
    l_source_file := TRIM(substr(l_remaining, 1, l_loc));
    l_remaining   := TRIM(substr(l_remaining, l_loc + 1));
    -- revision
    l_loc       := instr(l_remaining, ' ', 1, 1);
    l_revision  := TRIM(substr(l_remaining, 1, l_loc));
    l_remaining := TRIM(substr(l_remaining, l_loc + 1));
    -- l_rev_date
    l_loc      := instr(l_remaining, ' ', 1, 2);
    l_rev_date := TRIM(substr(l_remaining, 1, l_loc));
    -- rev_author
    l_rev_author := TRIM(rtrim(substr(l_remaining, l_loc + 1), '$'));
    -- Call proc to log error
    log_detailed_error(l_source_file, l_revision, l_rev_author, l_rev_date, p_proc_name, p_error_loc, p_error_data, p_plsql_unit, p_plsql_line, p_sqlcode, p_sqlerrm);
  END log_error;

  PROCEDURE log_action(p_app_name VARCHAR2, p_action_type VARCHAR2, p_log_comment VARCHAR2) IS
    PRAGMA AUTONOMOUS_TRANSACTION;
  BEGIN
    INSERT INTO action_audit_log
      (log_timestamp, user_name, edition, app_name, action_type, log_comment)
    VALUES
      (systimestamp,
       USER,
       sys_context('USERENV', 'CURRENT_EDITION_NAME'),
       p_app_name,
       p_action_type,
       p_log_comment);
    COMMIT;
  END log_action;

  PROCEDURE log_data_change(p_app_name      VARCHAR2,
                            p_owner         VARCHAR2,
                            p_table_name    VARCHAR2,
                            p_action_type   VARCHAR2,
                            p_dml_type      VARCHAR2,
                            p_recs_affected INTEGER,
                            p_log_comment   VARCHAR2) IS
    PRAGMA AUTONOMOUS_TRANSACTION;
  BEGIN
    INSERT INTO data_audit_log
      (log_timestamp,
       user_name,
       edition,
       app_name,
       tab_owner,
       tab_name,
       action_type,
       dml_type,
       recs_affected,
       log_comment)
    VALUES
      (systimestamp,
       USER,
       sys_context('USERENV', 'CURRENT_EDITION_NAME'),
       p_app_name,
       p_owner,
       p_table_name,
       p_action_type,
       p_dml_type,
       p_recs_affected,
       p_log_comment);
    COMMIT;
  END log_data_change;

  PROCEDURE log_ddl_change(p_object_owner VARCHAR2,
                           p_object_name  VARCHAR2,
                           p_object_type  VARCHAR2,
                           p_parent_name  VARCHAR2,
                           p_ticket       VARCHAR2,
                           p_sql_executed VARCHAR2,
                           p_message      VARCHAR2,
                           p_svn_id       VARCHAR2) IS
    PRAGMA AUTONOMOUS_TRANSACTION;
    l_source_file  err_log.source_file%TYPE;
    l_revision     err_log.revision%TYPE;
    l_rev_author   err_log.rev_author%TYPE;
    l_rev_date     err_log.rev_date%TYPE;
    l_remaining    VARCHAR2(2000);
    l_loc          PLS_INTEGER;
    l_rollback_ddl VARCHAR2(2000);
  BEGIN
    -- Parse the p_svn_id argument into parts to store in the table
    l_remaining := TRIM(ltrim(p_svn_id, '$Id:'));
    -- source_file
    l_loc         := instr(l_remaining, ' ', 1, 1);
    l_source_file := TRIM(substr(l_remaining, 1, l_loc));
    l_remaining   := TRIM(substr(l_remaining, l_loc + 1));
    -- revision
    l_loc       := instr(l_remaining, ' ', 1, 1);
    l_revision  := TRIM(substr(l_remaining, 1, l_loc));
    l_remaining := TRIM(substr(l_remaining, l_loc + 1));
    -- l_rev_date
    l_loc      := instr(l_remaining, ' ', 1, 2);
    l_rev_date := TRIM(substr(l_remaining, 1, l_loc));
    -- rev_author
    l_rev_author := TRIM(rtrim(substr(l_remaining, l_loc + 1), '$'));
    -- generate rollback DDL
    IF p_object_type IN ('TABLE', 'SEQUENCE', 'JOB', 'CONSTRAINT', 'INDEX', 'COLUMN') THEN
      l_rollback_ddl := 'exec deploy_utils.drop_object(''' || p_ticket || ''',''' ||
                        p_object_type || ''',''' || p_object_owner || ''',''' || p_object_name ||
                        ''')';
    END IF;
    -- Insert this info into the table
    INSERT INTO ddl_audit_log
      (object_owner,
       object_name,
       object_type,
       parent_name,
       ticket,
       sql_executed,
       edition,
       source_file,
       revision,
       rev_author,
       rev_date,
       message,
       rollback_ddl)
    VALUES
      (p_object_owner,
       p_object_name,
       p_object_type,
       p_parent_name,
       p_ticket,
       p_sql_executed,
       sys_context('USERENV', 'CURRENT_EDITION_NAME'),
       l_source_file,
       l_revision,
       l_rev_author,
       l_rev_date,
       p_message,
       l_rollback_ddl);
    COMMIT;
  END log_ddl_change;

  PROCEDURE log_pkg_init(p_package VARCHAR2, p_svn_id VARCHAR2) IS
    PRAGMA AUTONOMOUS_TRANSACTION;
    l_source_file  err_log.source_file%TYPE;
    l_revision     err_log.revision%TYPE;
    l_rev_author   err_log.rev_author%TYPE;
    l_rev_date     err_log.rev_date%TYPE;
    l_remaining    VARCHAR2(2000);
    l_loc          PLS_INTEGER;
    v_last_load_ts pkg_run_log.last_load_ts%TYPE;
  BEGIN
    -- check whether it has been at least an hour since we've updated this record
    SELECT MAX(last_load_ts) INTO v_last_load_ts FROM pkg_run_log WHERE PACKAGE = p_package;
    IF (v_last_load_ts IS NULL OR v_last_load_ts < current_timestamp - INTERVAL '60' minute) THEN
      -- Parse the p_svn_id argument into parts to store in the table
      l_remaining := TRIM(ltrim(p_svn_id, '$Id:'));
      -- source_file
      l_loc         := instr(l_remaining, ' ', 1, 1);
      l_source_file := TRIM(substr(l_remaining, 1, l_loc));
      l_remaining   := TRIM(substr(l_remaining, l_loc + 1));
      -- revision
      l_loc       := instr(l_remaining, ' ', 1, 1);
      l_revision  := TRIM(substr(l_remaining, 1, l_loc));
      l_remaining := TRIM(substr(l_remaining, l_loc + 1));
      -- l_rev_date
      l_loc      := instr(l_remaining, ' ', 1, 2);
      l_rev_date := TRIM(substr(l_remaining, 1, l_loc));
      -- rev_author
      l_rev_author := TRIM(rtrim(substr(l_remaining, l_loc + 1), '$'));
      -- Merge this info into the table
      MERGE INTO pkg_run_log a
      USING (SELECT p_package PACKAGE,
                    l_revision revision,
                    sys_context('USERENV', 'CURRENT_EDITION_NAME') edition,
                    l_source_file source_file,
                    l_rev_date rev_date,
                    l_rev_author rev_author,
                    systimestamp last_load_ts,
                    USER last_load_user
               FROM dual) b
      ON (a.package = b.package AND a.revision = b.revision AND a.edition = b.edition)
      WHEN NOT MATCHED THEN
        INSERT
          (PACKAGE,
           revision,
           edition,
           source_file,
           rev_date,
           rev_author,
           last_load_ts,
           last_load_user)
        VALUES
          (p_package,
           l_revision,
           sys_context('USERENV', 'CURRENT_EDITION_NAME'),
           l_source_file,
           l_rev_date,
           l_rev_author,
           systimestamp,
           USER)
      WHEN MATCHED THEN
        UPDATE
           SET a.source_file    = b.source_file,
               a.rev_date       = b.rev_date,
               a.rev_author     = b.rev_author,
               a.last_load_ts   = b.last_load_ts,
               a.last_load_user = b.last_load_user;
      COMMIT;
    END IF;
  END log_pkg_init;

BEGIN
  log_pkg_init($$PLSQL_UNIT, lc_svn_id);
END audit_pkg;
/
SHOW ERRORS
