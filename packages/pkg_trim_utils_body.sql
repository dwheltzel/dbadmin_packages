CREATE OR REPLACE PACKAGE BODY COMSPOC_DBA.PKG_TRIM_UTILS
-- Author: dheltzel
 AS

  LC_SVN_ID VARCHAR2(200) := 'trim_utils_body.sql dheltzel';

  LV_PROC_NAME ERR_LOG.PROC_NAME%TYPE;

  LV_COMMENT ERR_LOG.SOURCE_FILE%TYPE := 'Starting';

  -- Rename partitions and subpartitions with system generated names
  PROCEDURE PART_RENAME_API_REQUEST_LOG IS
    C_HIGH_VALUE VARCHAR2(30);
    V_SUFFIX     VARCHAR2(5);
    N_HIGH_VALUE PLS_INTEGER;
  BEGIN
    LV_PROC_NAME := 'part_rename_api_request_log';
    LV_COMMENT   := 'Renaming Partitions';
    FOR R IN (SELECT PARTITION_NAME, HIGH_VALUE
                FROM DBA_TAB_PARTITIONS
               WHERE TABLE_OWNER = 'WEBAPI'
                 AND TABLE_NAME = 'API_REQUEST_LOG2_'
                 AND PARTITION_NAME LIKE 'SYS%') LOOP
      C_HIGH_VALUE := R.HIGH_VALUE;
      N_HIGH_VALUE := TO_NUMBER(TRIM(C_HIGH_VALUE)) - 1;
      /*      dbms_output.put_line('alter table WEBAPI.API_REQUEST_LOG2_ rename partition ' ||
      r.partition_name || ' to ARL_' ||
      to_char(n_high_value) || ';');*/
      EXECUTE IMMEDIATE 'alter table WEBAPI.API_REQUEST_LOG2_ rename partition ' ||
                        R.PARTITION_NAME || ' to ARL_' ||
                        TO_CHAR(N_HIGH_VALUE);
    END LOOP;
    LV_COMMENT := 'Renaming Subpartitions';
    FOR R IN (SELECT PARTITION_NAME, SUBPARTITION_NAME, HIGH_VALUE
                FROM DBA_TAB_SUBPARTITIONS
               WHERE TABLE_OWNER = 'WEBAPI'
                 AND TABLE_NAME = 'API_REQUEST_LOG2_'
                 AND SUBPARTITION_NAME LIKE 'SYS%') LOOP
      C_HIGH_VALUE := R.HIGH_VALUE;
      CASE C_HIGH_VALUE
        WHEN '2' THEN
          V_SUFFIX := 'JAN';
        WHEN '3' THEN
          V_SUFFIX := 'FEB';
        WHEN '4' THEN
          V_SUFFIX := 'MAR';
        WHEN '5' THEN
          V_SUFFIX := 'APR';
        WHEN '6' THEN
          V_SUFFIX := 'MAY';
        WHEN '7' THEN
          V_SUFFIX := 'JUN';
        WHEN '8' THEN
          V_SUFFIX := 'JUL';
        WHEN '9' THEN
          V_SUFFIX := 'AUG';
        WHEN '10' THEN
          V_SUFFIX := 'SEP';
        WHEN '11' THEN
          V_SUFFIX := 'OCT';
        WHEN '12' THEN
          V_SUFFIX := 'NOV';
        WHEN 'MAXVALUE' THEN
          V_SUFFIX := 'DECE';
      END CASE;
      /*      dbms_output.put_line('alter table WEBAPI.API_REQUEST_LOG2_ rename subpartition ' ||
      r.subpartition_name || ' to ' ||
      r.partition_name || '_' || v_suffix || ';');*/
      EXECUTE IMMEDIATE 'alter table WEBAPI.API_REQUEST_LOG2_ rename subpartition ' ||
                        R.SUBPARTITION_NAME || ' to ' || R.PARTITION_NAME || '_' ||
                        V_SUFFIX;
    END LOOP;
  EXCEPTION
    WHEN OTHERS THEN
<<<<<<< Updated upstream
      pkg_audit.log_error(lc_svn_id,
                                  lv_proc_name,
                                  lv_comment,
                                  'WEBAPI.API_REQUEST_LOG_',
                                  $$PLSQL_UNIT,
                                  $$PLSQL_LINE,
                                  SQLCODE,
                                  SQLERRM);
  END part_rename_api_request_log;
=======
      PKG_AUDIT.LOG_ERROR(LC_SVN_ID,
                          LV_PROC_NAME,
                          LV_COMMENT,
                          'WEBAPI.API_REQUEST_LOG_',
                          $$PLSQL_UNIT,
                          $$PLSQL_LINE,
                          SQLCODE,
                          SQLERRM);
  END PART_RENAME_API_REQUEST_LOG;
>>>>>>> Stashed changes

  FUNCTION CHK_SETTINGS(VAR_NAME IN VARCHAR2) RETURN VARCHAR2 IS
    RESULT VARCHAR2(100);
  BEGIN
    RESULT := PKG_REGISTRY.GET_VALUE(VAR_NAME, 'TRIM');
    IF RESULT IS NOT NULL THEN
      DELETE FROM REGISTRYTABLE
       WHERE NAMESPACE = 'TRIM'
         AND NAME = VAR_NAME
         AND IMMUTABLE = 'N';
    END IF;
    RETURN(RESULT);
  END CHK_SETTINGS;

  PROCEDURE TRIM_LARGE_TABLE(P_OWNER           VARCHAR2,
                             P_TABLE_NAME      VARCHAR2,
                             P_SQL             VARCHAR2,
                             P_KEEP_DAYS       PLS_INTEGER DEFAULT 365,
                             P_SLEEP_TIME      PLS_INTEGER DEFAULT 2,
                             P_CHUNK_SIZE      PLS_INTEGER DEFAULT 500,
                             P_COMMIT_INTERVAL PLS_INTEGER DEFAULT 1000,
                             P_CHKPNT_INTERVAL PLS_INTEGER DEFAULT 100,
                             P_MAX_RUN_TIME    PLS_INTEGER DEFAULT 0,
                             P_EXIT_TIME       VARCHAR2 DEFAULT NULL,
                             P_LOG_ALWAYS      VARCHAR2 DEFAULT 'N') IS
    L_CHKPNT_COUNT     PLS_INTEGER := 0;
    L_UNCOMMITTED_RECS PLS_INTEGER := 0;
    L_DELETED_RECS     PLS_INTEGER := 0;
    L_AFFECTED_RECS    PLS_INTEGER;
    L_COMMIT_CNT       PLS_INTEGER := 0;
    L_ROW_COUNT        PLS_INTEGER;
    L_START_TIME       DATE;
    L_REGISTRY_VALUE   VARCHAR2(100);
    L_SLEEP_TIME       PLS_INTEGER := P_SLEEP_TIME;
    L_COMMIT_INTERVAL  PLS_INTEGER := P_COMMIT_INTERVAL;
    L_CHKPNT_INTERVAL  PLS_INTEGER := P_CHKPNT_INTERVAL;
  BEGIN
    LV_PROC_NAME := 'trim_large_table';
    LV_COMMENT   := 'Report runtime parameters';
    DBMS_APPLICATION_INFO.SET_MODULE(LV_PROC_NAME, P_TABLE_NAME);
    DBMS_APPLICATION_INFO.SET_CLIENT_INFO('Starting up');
    -- This process is restartable. If an existing task with this table name exists, check for unprocessed chunks
    LV_COMMENT := 'Check for an existing task';
    SELECT COUNT(*)
      INTO L_ROW_COUNT
      FROM SYS.DBA_PARALLEL_EXECUTE_TASKS
     WHERE TASK_NAME = P_TABLE_NAME;
    IF (L_ROW_COUNT > 0) THEN
      LV_COMMENT := 'Check for unprocessed chunks';
      SELECT COUNT(*)
        INTO L_ROW_COUNT
        FROM SYS.DBA_PARALLEL_EXECUTE_CHUNKS
       WHERE TASK_NAME = P_TABLE_NAME
         AND STATUS <> 'PROCESSED';
      -- If there are no unprocessed chunks for the task, drop it
      IF (L_ROW_COUNT = 0) THEN
        LV_COMMENT := 'Drop the existing task';
        BEGIN
          DBMS_PARALLEL_EXECUTE.DROP_TASK(P_TABLE_NAME);
        EXCEPTION
          WHEN OTHERS THEN
            NULL;
        END;
      END IF;
    END IF;
    -- If the task does not exist (or was just dropped because the last run completed), create it and all the chunks
    IF (L_ROW_COUNT = 0) THEN
      LV_COMMENT := 'Create the Objects, task, and chunk by ROWID';
      DBMS_PARALLEL_EXECUTE.CREATE_TASK(P_TABLE_NAME);
      DBMS_PARALLEL_EXECUTE.CREATE_CHUNKS_BY_ROWID(P_TABLE_NAME,
                                                   P_OWNER,
                                                   P_TABLE_NAME,
                                                   FALSE,
                                                   P_CHUNK_SIZE);
    END IF;
    LV_COMMENT   := 'Process each chunk and commit';
    L_START_TIME := SYSDATE;
    -- Process each chunk and commit.
    FOR CHUNK IN (SELECT CHUNK_ID, START_ROWID, END_ROWID
                    FROM SYS.DBA_PARALLEL_EXECUTE_CHUNKS
                   WHERE TASK_NAME = P_TABLE_NAME
                     AND STATUS <> 'PROCESSED'
                   ORDER BY CHUNK_ID) LOOP
      BEGIN
        EXECUTE IMMEDIATE P_SQL
          USING CHUNK.START_ROWID, CHUNK.END_ROWID, P_KEEP_DAYS;
        L_AFFECTED_RECS    := SQL%ROWCOUNT;
        L_UNCOMMITTED_RECS := L_UNCOMMITTED_RECS + L_AFFECTED_RECS;
        L_DELETED_RECS     := L_DELETED_RECS + L_AFFECTED_RECS;
        DBMS_PARALLEL_EXECUTE.SET_CHUNK_STATUS(P_TABLE_NAME,
                                               CHUNK.CHUNK_ID,
                                               DBMS_PARALLEL_EXECUTE.PROCESSED);
        IF (L_UNCOMMITTED_RECS > L_COMMIT_INTERVAL) THEN
          LV_COMMENT := 'Do commit';
          COMMIT;
          L_UNCOMMITTED_RECS := 0;
          L_COMMIT_CNT       := L_COMMIT_CNT + 1;
          -- update the record count and other stats
          DBMS_APPLICATION_INFO.SET_CLIENT_INFO('Deleted ' ||
                                                L_DELETED_RECS ||
                                                ' records, with ' ||
                                                L_COMMIT_CNT ||
                                                ' commits, and ' ||
                                                L_CHKPNT_COUNT ||
                                                ' checkpoints (' ||
                                                L_COMMIT_INTERVAL || ':' ||
                                                L_SLEEP_TIME || ' secs:' ||
                                                L_CHKPNT_INTERVAL || ')');
          -- before we sleep, check the registry table for updates
          -- See if we should quit the trim
          LV_COMMENT       := 'Check for new runtime params';
          L_REGISTRY_VALUE := CHK_SETTINGS(P_TABLE_NAME || '_QUIT');
          IF L_REGISTRY_VALUE IS NOT NULL THEN
            EXIT;
          END IF;
          -- change any values
          -- seconds to sleep after a commit
          L_SLEEP_TIME := NVL(CHK_SETTINGS(P_TABLE_NAME || '_SLEEP'),
                              L_SLEEP_TIME);
          -- Commit after this many record changes
          L_COMMIT_INTERVAL := NVL(CHK_SETTINGS(P_TABLE_NAME || '_COMMIT'),
                                   L_COMMIT_INTERVAL);
          -- Checkpoint after this many commits
          L_CHKPNT_INTERVAL := NVL(CHK_SETTINGS(P_TABLE_NAME ||
                                                '_CHECKPOINT'),
                                   L_CHKPNT_INTERVAL);
          LV_COMMENT        := 'Sleeping';
          DBMS_SESSION.SLEEP(L_SLEEP_TIME);
          LV_COMMENT := 'Checkpoint if needed';
          IF MOD(L_COMMIT_CNT, L_CHKPNT_INTERVAL) = 0 THEN
            EXECUTE IMMEDIATE 'alter system checkpoint';
            L_CHKPNT_COUNT := L_CHKPNT_COUNT + 1;
          END IF;
        END IF;
      EXCEPTION
        WHEN OTHERS THEN
          DBMS_PARALLEL_EXECUTE.SET_CHUNK_STATUS(P_TABLE_NAME,
                                                 CHUNK.CHUNK_ID,
                                                 DBMS_PARALLEL_EXECUTE.PROCESSED_WITH_ERROR,
                                                 SQLCODE,
                                                 SQLERRM);
      END;
      -- p_max_run_time is in minutes (60 * 24)
      LV_COMMENT := 'Check if it is time to quit';
      IF ((P_MAX_RUN_TIME > 0) AND
         (1440 * (SYSDATE - L_START_TIME)) > P_MAX_RUN_TIME) THEN
        EXIT;
      END IF;
      -- p_exit_time is a string like '23:30'
      IF ((P_EXIT_TIME IS NOT NULL) AND
         (SYSDATE >
         TO_DATE(TO_CHAR(TRUNC(SYSDATE), 'MM/DD/YYYY') || P_EXIT_TIME,
                   'MM/DD/YYYYHH24:MI'))) THEN
        EXIT;
      END IF;
    END LOOP;
    COMMIT;
<<<<<<< Updated upstream
    lv_comment := 'Log final counts';
    IF (l_deleted_recs > 0 OR p_log_always = 'Y') THEN
      pkg_audit.log_data_change(lv_proc_name,
                                p_owner,
                                p_table_name,
=======
    LV_COMMENT := 'Log final counts';
    IF (L_DELETED_RECS > 0 OR P_LOG_ALWAYS = 'Y') THEN
      PKG_AUDIT.LOG_DATA_CHANGE(LV_PROC_NAME,
                                P_OWNER,
                                P_TABLE_NAME,
>>>>>>> Stashed changes
                                'Trim',
                                'D',
                                L_DELETED_RECS,
                                '');
    END IF;
    /* dbms_output.put_line('Total deleted records: ' || l_deleted_recs);
    dbms_output.put_line('Total commits: ' || l_commit_cnt);
    dbms_output.put_line('Total checkpoints: ' || l_chkpnt_count);*/
  EXCEPTION
    WHEN OTHERS THEN
<<<<<<< Updated upstream
      pkg_audit.log_error(lc_svn_id,
                                  lv_proc_name,
                                  lv_comment,
                                  p_owner || '.' || p_table_name,
                                  $$PLSQL_UNIT,
                                  $$PLSQL_LINE,
                                  SQLCODE,
                                  SQLERRM);
  END trim_large_table;
=======
      PKG_AUDIT.LOG_ERROR(LC_SVN_ID,
                          LV_PROC_NAME,
                          LV_COMMENT,
                          P_OWNER || '.' || P_TABLE_NAME,
                          $$PLSQL_UNIT,
                          $$PLSQL_LINE,
                          SQLCODE,
                          SQLERRM);
  END TRIM_LARGE_TABLE;
>>>>>>> Stashed changes

  -- Generic proc to delete records from a small table
  PROCEDURE TRIM_SMALL_TABLE(P_OWNER      VARCHAR2,
                             P_TABLE_NAME VARCHAR2,
                             P_SQL        VARCHAR2,
                             P_LOG_ALWAYS VARCHAR2 DEFAULT 'N') IS
    L_DELETED_RECS PLS_INTEGER := 0;
  BEGIN
    LV_PROC_NAME := 'trim_small_table';
    LV_COMMENT   := 'Report runtime parameters';
    DBMS_APPLICATION_INFO.SET_MODULE(LV_PROC_NAME, P_TABLE_NAME);
    DBMS_APPLICATION_INFO.SET_CLIENT_INFO('Starting up');
    LV_COMMENT := 'Run delete';
    EXECUTE IMMEDIATE P_SQL;
    L_DELETED_RECS := SQL%ROWCOUNT;
    COMMIT;
<<<<<<< Updated upstream
    lv_comment := 'Log final counts';
    IF (l_deleted_recs > 0 OR p_log_always = 'Y') THEN
      pkg_audit.log_data_change(lv_proc_name,
                                p_owner,
                                p_table_name,
=======
    LV_COMMENT := 'Log final counts';
    IF (L_DELETED_RECS > 0 OR P_LOG_ALWAYS = 'Y') THEN
      PKG_AUDIT.LOG_DATA_CHANGE(LV_PROC_NAME,
                                P_OWNER,
                                P_TABLE_NAME,
>>>>>>> Stashed changes
                                'Trim',
                                'D',
                                L_DELETED_RECS,
                                '');
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
<<<<<<< Updated upstream
      pkg_audit.log_error(lc_svn_id,
                                  lv_proc_name,
                                  lv_comment,
                                  p_owner || '.' || p_table_name,
                                  $$PLSQL_UNIT,
                                  $$PLSQL_LINE,
                                  SQLCODE,
                                  SQLERRM);
  END trim_small_table;
=======
      PKG_AUDIT.LOG_ERROR(LC_SVN_ID,
                          LV_PROC_NAME,
                          LV_COMMENT,
                          P_OWNER || '.' || P_TABLE_NAME,
                          $$PLSQL_UNIT,
                          $$PLSQL_LINE,
                          SQLCODE,
                          SQLERRM);
  END TRIM_SMALL_TABLE;
>>>>>>> Stashed changes

  PROCEDURE TRIM_PAR_EXEC_TASKS(P_DAYS PLS_INTEGER DEFAULT 7) IS
    V_CNT PLS_INTEGER;
  BEGIN
<<<<<<< Updated upstream
    lv_proc_name := 'trim_par_exec_tasks';
    SELECT COUNT(DISTINCT task_name)
      INTO v_cnt
      FROM sys.dba_parallel_execute_chunks
     WHERE end_ts < SYSDATE - p_days
       AND task_owner = USER;
    IF (v_cnt > 0) THEN
      pkg_audit.log_action(lv_proc_name, 'Trim', 'Keep Days: ' || p_days);
      FOR c_rec IN (SELECT DISTINCT task_name
                      FROM sys.dba_parallel_execute_chunks
                     WHERE end_ts < SYSDATE - p_days
                       AND task_owner = USER) LOOP
        sys.dbms_parallel_execute.drop_task(c_rec.task_name);
      END LOOP;
      pkg_audit.log_data_change(lv_proc_name,
=======
    LV_PROC_NAME := 'trim_par_exec_tasks';
    SELECT COUNT(DISTINCT TASK_NAME)
      INTO V_CNT
      FROM SYS.DBA_PARALLEL_EXECUTE_CHUNKS
     WHERE END_TS < SYSDATE - P_DAYS
       AND TASK_OWNER = USER;
    IF (V_CNT > 0) THEN
      PKG_AUDIT.LOG_ACTION(LV_PROC_NAME, 'Trim', 'Keep Days: ' || P_DAYS);
      FOR C_REC IN (SELECT DISTINCT TASK_NAME
                      FROM SYS.DBA_PARALLEL_EXECUTE_CHUNKS
                     WHERE END_TS < SYSDATE - P_DAYS
                       AND TASK_OWNER = USER) LOOP
        SYS.DBMS_PARALLEL_EXECUTE.DROP_TASK(C_REC.TASK_NAME);
      END LOOP;
      PKG_AUDIT.LOG_DATA_CHANGE(LV_PROC_NAME,
>>>>>>> Stashed changes
                                'SYS',
                                'DBA_PARALLEL_EXECUTE',
                                'Trim',
                                'D',
                                V_CNT,
                                'Cleanup of Parallel Execute Tasks older than ' ||
                                P_DAYS || ' days.');
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
<<<<<<< Updated upstream
      pkg_audit.log_error(lc_svn_id,
                                  lv_proc_name,
                                  lv_comment,
                                  '',
                                  $$PLSQL_UNIT,
                                  $$PLSQL_LINE,
                                  SQLCODE,
                                  SQLERRM);
  END trim_par_exec_tasks;
=======
      PKG_AUDIT.LOG_ERROR(LC_SVN_ID,
                          LV_PROC_NAME,
                          LV_COMMENT,
                          '',
                          $$PLSQL_UNIT,
                          $$PLSQL_LINE,
                          SQLCODE,
                          SQLERRM);
  END TRIM_PAR_EXEC_TASKS;
>>>>>>> Stashed changes

  /* Master trim procedures
  These call the other procedures with standard params for each environment
  */
  PROCEDURE QA_ROUTINE_TRIM IS
  BEGIN
    LV_PROC_NAME := 'qa_routine_trim';
    TRIM_PAR_EXEC_TASKS;
  EXCEPTION
    WHEN OTHERS THEN
<<<<<<< Updated upstream
      pkg_audit.log_error(lc_svn_id,
                                  lv_proc_name,
                                  lv_comment,
                                  '',
                                  $$PLSQL_UNIT,
                                  $$PLSQL_LINE,
                                  SQLCODE,
                                  SQLERRM);
  END qa_routine_trim;
=======
      PKG_AUDIT.LOG_ERROR(LC_SVN_ID,
                          LV_PROC_NAME,
                          LV_COMMENT,
                          '',
                          $$PLSQL_UNIT,
                          $$PLSQL_LINE,
                          SQLCODE,
                          SQLERRM);
  END QA_ROUTINE_TRIM;
>>>>>>> Stashed changes

  PROCEDURE STAGE_ROUTINE_TRIM IS
  BEGIN
    LV_PROC_NAME := 'stage_routine_trim';
    TRIM_PAR_EXEC_TASKS;
  EXCEPTION
    WHEN OTHERS THEN
<<<<<<< Updated upstream
      pkg_audit.log_error(lc_svn_id,
                                  lv_proc_name,
                                  lv_comment,
                                  '',
                                  $$PLSQL_UNIT,
                                  $$PLSQL_LINE,
                                  SQLCODE,
                                  SQLERRM);
  END stage_routine_trim;
=======
      PKG_AUDIT.LOG_ERROR(LC_SVN_ID,
                          LV_PROC_NAME,
                          LV_COMMENT,
                          '',
                          $$PLSQL_UNIT,
                          $$PLSQL_LINE,
                          SQLCODE,
                          SQLERRM);
  END STAGE_ROUTINE_TRIM;
>>>>>>> Stashed changes

  PROCEDURE PROD_ROUTINE_TRIM IS
  BEGIN
    LV_PROC_NAME := 'prod_routine_trim';
    TRIM_PAR_EXEC_TASKS;
  EXCEPTION
    WHEN OTHERS THEN
<<<<<<< Updated upstream
      pkg_audit.log_error(lc_svn_id,
                                  lv_proc_name,
                                  lv_comment,
                                  '',
                                  $$PLSQL_UNIT,
                                  $$PLSQL_LINE,
                                  SQLCODE,
                                  SQLERRM);
  END prod_routine_trim;

BEGIN
  pkg_audit.log_pkg_init($$PLSQL_UNIT, lc_svn_id);
=======
      PKG_AUDIT.LOG_ERROR(LC_SVN_ID,
                          LV_PROC_NAME,
                          LV_COMMENT,
                          '',
                          $$PLSQL_UNIT,
                          $$PLSQL_LINE,
                          SQLCODE,
                          SQLERRM);
  END PROD_ROUTINE_TRIM;

BEGIN
  PKG_AUDIT.LOG_PKG_INIT($$PLSQL_UNIT, LC_SVN_ID);
>>>>>>> Stashed changes
END PKG_TRIM_UTILS;
/
