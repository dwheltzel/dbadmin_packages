CREATE OR REPLACE PACKAGE PKG_TRIM_UTILS
-- Author: dheltzel
AUTHID CURRENT_USER AS

  -- Rename partitions and subpartitions with system generated names
  PROCEDURE part_rename_api_request_log;

  -- Generic proc to process SQL on a large table
  PROCEDURE trim_large_table(p_owner           VARCHAR2,
                              p_table_name      VARCHAR2,
                              p_sql             VARCHAR2,
                              p_keep_days       PLS_INTEGER DEFAULT 365,
                              p_sleep_time      PLS_INTEGER DEFAULT 2,
                              p_chunk_size      PLS_INTEGER DEFAULT 500,
                              p_commit_interval PLS_INTEGER DEFAULT 1000,
                              p_chkpnt_interval PLS_INTEGER DEFAULT 100,
                              p_max_run_time    PLS_INTEGER DEFAULT 0,
                              p_exit_time       VARCHAR2 DEFAULT NULL,
                              p_log_always      VARCHAR2 DEFAULT 'N');

  -- Generic proc to delete records from a small table
  PROCEDURE trim_small_table(p_owner      VARCHAR2,
                              p_table_name VARCHAR2,
                              p_sql        VARCHAR2,
                              p_log_always VARCHAR2 DEFAULT 'N');

  PROCEDURE trim_par_exec_tasks(p_days PLS_INTEGER DEFAULT 7);

  /* Master trim procedures
  These call the other procedures with standard params for each environment
  */
  PROCEDURE qa_routine_trim;

  PROCEDURE stage_routine_trim;

  PROCEDURE prod_routine_trim;

END PKG_TRIM_UTILS;
/

