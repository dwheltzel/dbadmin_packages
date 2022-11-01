SET DEFINE OFF

CREATE OR REPLACE PACKAGE BODY purge_utils
-- File purge_utils_body.sql
-- Author: dheltzel
-- Create Date 2013-11-20
 AS

  lc_svn_id VARCHAR2(200) := 'purge_utils_body.sql dheltzel';

  lv_proc_name err_log.proc_name%TYPE;

  lv_comment err_log.source_file%TYPE := 'Starting';

  -- Rename partitions and subpartitions with system generated names
  PROCEDURE part_rename_api_request_log IS
    c_high_value VARCHAR2(30);
    v_suffix     VARCHAR2(5);
    n_high_value PLS_INTEGER;
  BEGIN
    lv_proc_name := 'part_rename_api_request_log';
    lv_comment   := 'Renaming Partitions';
    FOR r IN (SELECT partition_name, high_value
                FROM dba_tab_partitions
               WHERE table_owner = 'WEBAPI'
                 AND table_name = 'API_REQUEST_LOG2_'
                 AND partition_name LIKE 'SYS%') LOOP
      c_high_value := r.high_value;
      n_high_value := to_number(TRIM(c_high_value)) - 1;
      /*      dbms_output.put_line('alter table WEBAPI.API_REQUEST_LOG2_ rename partition ' ||
      r.partition_name || ' to ARL_' ||
      to_char(n_high_value) || ';');*/
      EXECUTE IMMEDIATE 'alter table WEBAPI.API_REQUEST_LOG2_ rename partition ' ||
                        r.partition_name || ' to ARL_' ||
                        to_char(n_high_value);
    END LOOP;
    lv_comment := 'Renaming Subpartitions';
    FOR r IN (SELECT partition_name, subpartition_name, high_value
                FROM dba_tab_subpartitions
               WHERE table_owner = 'WEBAPI'
                 AND table_name = 'API_REQUEST_LOG2_'
                 AND subpartition_name LIKE 'SYS%') LOOP
      c_high_value := r.high_value;
      CASE c_high_value
        WHEN '2' THEN
          v_suffix := 'JAN';
        WHEN '3' THEN
          v_suffix := 'FEB';
        WHEN '4' THEN
          v_suffix := 'MAR';
        WHEN '5' THEN
          v_suffix := 'APR';
        WHEN '6' THEN
          v_suffix := 'MAY';
        WHEN '7' THEN
          v_suffix := 'JUN';
        WHEN '8' THEN
          v_suffix := 'JUL';
        WHEN '9' THEN
          v_suffix := 'AUG';
        WHEN '10' THEN
          v_suffix := 'SEP';
        WHEN '11' THEN
          v_suffix := 'OCT';
        WHEN '12' THEN
          v_suffix := 'NOV';
        WHEN 'MAXVALUE' THEN
          v_suffix := 'DECE';
      END CASE;
      /*      dbms_output.put_line('alter table WEBAPI.API_REQUEST_LOG2_ rename subpartition ' ||
      r.subpartition_name || ' to ' ||
      r.partition_name || '_' || v_suffix || ';');*/
      EXECUTE IMMEDIATE 'alter table WEBAPI.API_REQUEST_LOG2_ rename subpartition ' ||
                        r.subpartition_name || ' to ' || r.partition_name || '_' ||
                        v_suffix;
    END LOOP;
  EXCEPTION
    WHEN OTHERS THEN
      audit_pkg.log_error(lc_svn_id,
                                  lv_proc_name,
                                  lv_comment,
                                  'WEBAPI.API_REQUEST_LOG_',
                                  $$PLSQL_UNIT,
                                  $$PLSQL_LINE,
                                  SQLCODE,
                                  SQLERRM);
  END part_rename_api_request_log;

  FUNCTION chk_settings(var_name IN VARCHAR2) RETURN VARCHAR2 IS
    RESULT VARCHAR2(100);
  BEGIN
    RESULT := registry.get_value(var_name, 'PURGE');
    IF RESULT IS NOT NULL THEN
      DELETE FROM registrytable
       WHERE namespace = 'PURGE'
         AND NAME = var_name
         AND immutable = 'N';
    END IF;
    RETURN(RESULT);
  END chk_settings;

  PROCEDURE purge_large_table(p_owner           VARCHAR2,
                              p_table_name      VARCHAR2,
                              p_sql             VARCHAR2,
                              p_keep_days       PLS_INTEGER DEFAULT 365,
                              p_sleep_time      PLS_INTEGER DEFAULT 2,
                              p_chunk_size      PLS_INTEGER DEFAULT 500,
                              p_commit_interval PLS_INTEGER DEFAULT 1000,
                              p_chkpnt_interval PLS_INTEGER DEFAULT 100,
                              p_max_run_time    PLS_INTEGER DEFAULT 0,
                              p_exit_time       VARCHAR2 DEFAULT NULL,
                              p_log_always      VARCHAR2 DEFAULT 'N') IS
    l_chkpnt_count     PLS_INTEGER := 0;
    l_uncommitted_recs PLS_INTEGER := 0;
    l_deleted_recs     PLS_INTEGER := 0;
    l_affected_recs    PLS_INTEGER;
    l_commit_cnt       PLS_INTEGER := 0;
    l_row_count        PLS_INTEGER;
    l_start_time       DATE;
    l_registry_value   VARCHAR2(100);
    l_sleep_time       PLS_INTEGER := p_sleep_time;
    l_commit_interval  PLS_INTEGER := p_commit_interval;
    l_chkpnt_interval  PLS_INTEGER := p_chkpnt_interval;
  BEGIN
    lv_proc_name := 'purge_large_table';
    lv_comment   := 'Report runtime parameters';
    dbms_application_info.set_module(lv_proc_name, p_table_name);
    dbms_application_info.set_client_info('Starting up');
    -- This process is restartable. If an existing task with this table name exists, check for unprocessed chunks
    lv_comment := 'Check for an existing task';
    SELECT COUNT(*)
      INTO l_row_count
      FROM sys.dba_parallel_execute_tasks
     WHERE task_name = p_table_name;
    IF (l_row_count > 0) THEN
      lv_comment := 'Check for unprocessed chunks';
      SELECT COUNT(*)
        INTO l_row_count
        FROM sys.dba_parallel_execute_chunks
       WHERE task_name = p_table_name
         AND status <> 'PROCESSED';
      -- If there are no unprocessed chunks for the task, drop it
      IF (l_row_count = 0) THEN
        lv_comment := 'Drop the existing task';
        BEGIN
          dbms_parallel_execute.drop_task(p_table_name);
        EXCEPTION
          WHEN OTHERS THEN
            NULL;
        END;
      END IF;
    END IF;
    -- If the task does not exist (or was just dropped because the last run completed), create it and all the chunks
    IF (l_row_count = 0) THEN
      lv_comment := 'Create the Objects, task, and chunk by ROWID';
      dbms_parallel_execute.create_task(p_table_name);
      dbms_parallel_execute.create_chunks_by_rowid(p_table_name,
                                                   p_owner,
                                                   p_table_name,
                                                   FALSE,
                                                   p_chunk_size);
    END IF;
    lv_comment   := 'Process each chunk and commit';
    l_start_time := SYSDATE;
    -- Process each chunk and commit.
    FOR chunk IN (SELECT chunk_id, start_rowid, end_rowid
                    FROM sys.dba_parallel_execute_chunks
                   WHERE task_name = p_table_name
                     AND status <> 'PROCESSED'
                   ORDER BY chunk_id) LOOP
      BEGIN
        EXECUTE IMMEDIATE p_sql
          USING chunk.start_rowid, chunk.end_rowid, p_keep_days;
        l_affected_recs    := SQL%ROWCOUNT;
        l_uncommitted_recs := l_uncommitted_recs + l_affected_recs;
        l_deleted_recs     := l_deleted_recs + l_affected_recs;
        dbms_parallel_execute.set_chunk_status(p_table_name,
                                               chunk.chunk_id,
                                               dbms_parallel_execute.processed);
        IF (l_uncommitted_recs > l_commit_interval) THEN
          lv_comment := 'Do commit';
          COMMIT;
          l_uncommitted_recs := 0;
          l_commit_cnt       := l_commit_cnt + 1;
          -- update the record count and other stats
          dbms_application_info.set_client_info('Deleted ' ||
                                                l_deleted_recs ||
                                                ' records, with ' ||
                                                l_commit_cnt ||
                                                ' commits, and ' ||
                                                l_chkpnt_count ||
                                                ' checkpoints (' ||
                                                l_commit_interval || ':' ||
                                                l_sleep_time || ' secs:' ||
                                                l_chkpnt_interval || ')');
          -- before we sleep, check the registry table for updates
          -- See if we should quit the purge
          lv_comment       := 'Check for new runtime params';
          l_registry_value := chk_settings(p_table_name || '_QUIT');
          IF l_registry_value IS NOT NULL THEN
            EXIT;
          END IF;
          -- change any values
          -- seconds to sleep after a commit
          l_sleep_time := nvl(chk_settings(p_table_name || '_SLEEP'),
                              l_sleep_time);
          -- Commit after this many record changes
          l_commit_interval := nvl(chk_settings(p_table_name || '_COMMIT'),
                                   l_commit_interval);
          -- Checkpoint after this many commits
          l_chkpnt_interval := nvl(chk_settings(p_table_name ||
                                                '_CHECKPOINT'),
                                   l_chkpnt_interval);
          lv_comment        := 'Sleeping';
          dbms_lock.sleep(l_sleep_time);
          lv_comment := 'Checkpoint if needed';
          IF MOD(l_commit_cnt, l_chkpnt_interval) = 0 THEN
            EXECUTE IMMEDIATE 'alter system checkpoint';
            l_chkpnt_count := l_chkpnt_count + 1;
          END IF;
        END IF;
      EXCEPTION
        WHEN OTHERS THEN
          dbms_parallel_execute.set_chunk_status(p_table_name,
                                                 chunk.chunk_id,
                                                 dbms_parallel_execute.processed_with_error,
                                                 SQLCODE,
                                                 SQLERRM);
      END;
      -- p_max_run_time is in minutes (60 * 24)
      lv_comment := 'Check if it is time to quit';
      IF ((p_max_run_time > 0) AND
         (1440 * (SYSDATE - l_start_time)) > p_max_run_time) THEN
        EXIT;
      END IF;
      -- p_exit_time is a string like '23:30'
      IF ((p_exit_time IS NOT NULL) AND
         (SYSDATE >
         to_date(to_char(trunc(SYSDATE), 'MM/DD/YYYY') || p_exit_time,
                   'MM/DD/YYYYHH24:MI'))) THEN
        EXIT;
      END IF;
    END LOOP;
    COMMIT;
    lv_comment := 'Log final counts';
    IF (l_deleted_recs > 0 OR p_log_always = 'Y') THEN
      audit_pkg.log_data_change(lv_proc_name,
                                p_owner,
                                p_table_name,
                                'Purge',
                                'D',
                                l_deleted_recs,
                                '');
    END IF;
    /* dbms_output.put_line('Total deleted records: ' || l_deleted_recs);
    dbms_output.put_line('Total commits: ' || l_commit_cnt);
    dbms_output.put_line('Total checkpoints: ' || l_chkpnt_count);*/
  EXCEPTION
    WHEN OTHERS THEN
      audit_pkg.log_error(lc_svn_id,
                                  lv_proc_name,
                                  lv_comment,
                                  p_owner || '.' || p_table_name,
                                  $$PLSQL_UNIT,
                                  $$PLSQL_LINE,
                                  SQLCODE,
                                  SQLERRM);
  END purge_large_table;

  -- Generic proc to delete records from a small table
  PROCEDURE purge_small_table(p_owner      VARCHAR2,
                              p_table_name VARCHAR2,
                              p_sql        VARCHAR2,
                              p_log_always VARCHAR2 DEFAULT 'N') IS
    l_deleted_recs PLS_INTEGER := 0;
  BEGIN
    lv_proc_name := 'purge_small_table';
    lv_comment   := 'Report runtime parameters';
    dbms_application_info.set_module(lv_proc_name, p_table_name);
    dbms_application_info.set_client_info('Starting up');
    lv_comment := 'Run delete';
    EXECUTE IMMEDIATE p_sql;
    l_deleted_recs := SQL%ROWCOUNT;
    COMMIT;
    lv_comment := 'Log final counts';
    IF (l_deleted_recs > 0 OR p_log_always = 'Y') THEN
      audit_pkg.log_data_change(lv_proc_name,
                                p_owner,
                                p_table_name,
                                'Purge',
                                'D',
                                l_deleted_recs,
                                '');
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      audit_pkg.log_error(lc_svn_id,
                                  lv_proc_name,
                                  lv_comment,
                                  p_owner || '.' || p_table_name,
                                  $$PLSQL_UNIT,
                                  $$PLSQL_LINE,
                                  SQLCODE,
                                  SQLERRM);
  END purge_small_table;

  PROCEDURE purge_par_exec_tasks(p_days PLS_INTEGER DEFAULT 7) IS
    v_cnt PLS_INTEGER;
  BEGIN
    lv_proc_name := 'purge_par_exec_tasks';
    SELECT COUNT(DISTINCT task_name)
      INTO v_cnt
      FROM sys.dba_parallel_execute_chunks
     WHERE end_ts < SYSDATE - p_days
       AND task_owner = USER;
    IF (v_cnt > 0) THEN
      audit_pkg.log_action(lv_proc_name, 'Purge', 'Keep Days: ' || p_days);
      FOR c_rec IN (SELECT DISTINCT task_name
                      FROM sys.dba_parallel_execute_chunks
                     WHERE end_ts < SYSDATE - p_days
                       AND task_owner = USER) LOOP
        sys.dbms_parallel_execute.drop_task(c_rec.task_name);
      END LOOP;
      audit_pkg.log_data_change(lv_proc_name,
                                'SYS',
                                'DBA_PARALLEL_EXECUTE',
                                'Purge',
                                'D',
                                v_cnt,
                                'Cleanup of Parallel Execute Tasks older than ' ||
                                p_days || ' days.');
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      audit_pkg.log_error(lc_svn_id,
                                  lv_proc_name,
                                  lv_comment,
                                  '',
                                  $$PLSQL_UNIT,
                                  $$PLSQL_LINE,
                                  SQLCODE,
                                  SQLERRM);
  END purge_par_exec_tasks;

  /* Master purge procedures
  These call the other procedures with standard params for each environment
  */
  PROCEDURE qa_routine_purge IS
  BEGIN
    lv_proc_name := 'qa_routine_purge';
    purge_par_exec_tasks;
  EXCEPTION
    WHEN OTHERS THEN
      audit_pkg.log_error(lc_svn_id,
                                  lv_proc_name,
                                  lv_comment,
                                  '',
                                  $$PLSQL_UNIT,
                                  $$PLSQL_LINE,
                                  SQLCODE,
                                  SQLERRM);
  END qa_routine_purge;

  PROCEDURE stage_routine_purge IS
  BEGIN
    lv_proc_name := 'stage_routine_purge';
    purge_par_exec_tasks;
  EXCEPTION
    WHEN OTHERS THEN
      audit_pkg.log_error(lc_svn_id,
                                  lv_proc_name,
                                  lv_comment,
                                  '',
                                  $$PLSQL_UNIT,
                                  $$PLSQL_LINE,
                                  SQLCODE,
                                  SQLERRM);
  END stage_routine_purge;

  PROCEDURE prod_routine_purge IS
  BEGIN
    lv_proc_name := 'prod_routine_purge';
    purge_par_exec_tasks;
  EXCEPTION
    WHEN OTHERS THEN
      audit_pkg.log_error(lc_svn_id,
                                  lv_proc_name,
                                  lv_comment,
                                  '',
                                  $$PLSQL_UNIT,
                                  $$PLSQL_LINE,
                                  SQLCODE,
                                  SQLERRM);
  END prod_routine_purge;

BEGIN
  audit_pkg.log_pkg_init($$PLSQL_UNIT, lc_svn_id);
END purge_utils;
/
SHOW ERRORS
