CREATE OR REPLACE PACKAGE BODY PKG_DEPLOY_UTILS
-- Author: dheltzel
 AS
  LC_SVN_ID    VARCHAR2(200) := 'pkg_deploy_utils_body.sql dheltzel';
  LV_PROC_NAME ERR_LOG.PROC_NAME%TYPE;
  LV_COMMENT   ERR_LOG.ERROR_LOC%TYPE := 'Starting';

  /* Set and get this with the get_set_debug_level proc below
    defaults to 10, which prints everything. Setting this to:
    0 - suppresses all the errors to the screen
    5 - suppresses informational "success" messages, this will reduce the noise in the logs to only failed operations
    Note: exceptions will ALWAYS be written to the err_log table, and every operation is recorded in the audit tables
  */
  LV_DEBUG_LVL PLS_INTEGER := 10;

  PROCEDURE PKG_INFO IS
    V_EDITION VARCHAR2(35);
  BEGIN
    LV_PROC_NAME := 'pkg_info';
    LV_COMMENT   := 'Dumping deploy pkg info';
    DBMS_OUTPUT.PUT_LINE('$Revision: 4120 $');
    DBMS_OUTPUT.PUT_LINE('Date: 2014-04-21 11:11:42 -0400 (Mon, 21 Apr 2014) $');
    DBMS_OUTPUT.PUT_LINE('$Author: dheltzel $');
    DBMS_OUTPUT.PUT_LINE('pkg_deploy_utils_body.sql 4120 2014-04-21 15:11:42Z dheltzel $');
    LV_COMMENT := 'Getting the current edition';
    SELECT SYS_CONTEXT('USERENV', 'CURRENT_EDITION_NAME')
      INTO V_EDITION
      FROM DUAL;
    DBMS_OUTPUT.PUT_LINE('Edition: ' || V_EDITION);
    PKG_AUDIT.LOG_ERROR(LC_SVN_ID,
                        LV_PROC_NAME,
                        LV_COMMENT,
                        V_EDITION,
                        $$PLSQL_UNIT,
                        $$PLSQL_LINE,
                        SQLCODE,
                        SQLERRM);
  EXCEPTION
    WHEN OTHERS THEN
      PKG_AUDIT.LOG_ERROR(LC_SVN_ID,
                          LV_PROC_NAME,
                          LV_COMMENT,
                          V_EDITION,
                          $$PLSQL_UNIT,
                          $$PLSQL_LINE,
                          SQLCODE,
                          SQLERRM);
      IF LV_DEBUG_LVL > 0 THEN
        RAISE;
      END IF;
  END PKG_INFO;

  -- Get and/or Set Debug Level
  FUNCTION GET_SET_DEBUG_LEVEL(NEW_DEBUG_LVL IN INTEGER DEFAULT NULL)
    RETURN INTEGER IS
  BEGIN
    IF NEW_DEBUG_LVL IS NOT NULL THEN
      LV_DEBUG_LVL := NEW_DEBUG_LVL;
    END IF;
    RETURN(LV_DEBUG_LVL);
  END GET_SET_DEBUG_LEVEL;

  -- This will setup package variables and create an initial log entry for the deploy
  PROCEDURE INITIALIZE_DEPLOY(P_TICKET       VARCHAR,
                              P_RELEASE_NAME VARCHAR2,
                              P_SVN_REVISION VARCHAR2,
                              P_SVN_ID       VARCHAR2) IS
  BEGIN
    LV_PROC_NAME     := 'initialize_deploy';
    CURRENT_RELEASE  := P_RELEASE_NAME;
    CURRENT_REVISION := P_SVN_REVISION;
    PKG_AUDIT.LOG_DDL_CHANGE(P_RELEASE_NAME,
                             P_SVN_REVISION,
                             'DEPLOY',
                             NULL,
                             P_TICKET,
                             NULL,
                             NULL,
                             P_SVN_ID);
  EXCEPTION
    WHEN OTHERS THEN
      PKG_AUDIT.LOG_ERROR(LC_SVN_ID,
                          LV_PROC_NAME,
                          LV_COMMENT,
                          '',
                          $$PLSQL_UNIT,
                          $$PLSQL_LINE,
                          SQLCODE,
                          SQLERRM);
      IF LV_DEBUG_LVL > 0 THEN
        RAISE;
      END IF;
  END INITIALIZE_DEPLOY;

  FUNCTION GET_CURRENT_RELEASE RETURN VARCHAR2 IS
  BEGIN
    LV_PROC_NAME := 'get_current_release';
    RETURN(CURRENT_RELEASE);
  EXCEPTION
    WHEN OTHERS THEN
      PKG_AUDIT.LOG_ERROR(LC_SVN_ID,
                          LV_PROC_NAME,
                          LV_COMMENT,
                          '',
                          $$PLSQL_UNIT,
                          $$PLSQL_LINE,
                          SQLCODE,
                          SQLERRM);
      IF LV_DEBUG_LVL > 0 THEN
        RAISE;
      END IF;
  END GET_CURRENT_RELEASE;

  FUNCTION GET_CURRENT_REVISION RETURN VARCHAR2 IS
  BEGIN
    LV_PROC_NAME := 'get_current_revision';
    RETURN(CURRENT_REVISION);
  EXCEPTION
    WHEN OTHERS THEN
      PKG_AUDIT.LOG_ERROR(LC_SVN_ID,
                          LV_PROC_NAME,
                          LV_COMMENT,
                          '',
                          $$PLSQL_UNIT,
                          $$PLSQL_LINE,
                          SQLCODE,
                          SQLERRM);
      IF LV_DEBUG_LVL > 0 THEN
        RAISE;
      END IF;
  END GET_CURRENT_REVISION;

  FUNCTION IS_PARTITIONED_DB RETURN BOOLEAN IS
    L_VALUE VARCHAR2(10);
  BEGIN
    LV_PROC_NAME := 'is_partitioned_db';
    SELECT VALUE
      INTO L_VALUE
      FROM V$OPTION
     WHERE PARAMETER = 'Partitioning';
    IF L_VALUE = 'FALSE' THEN
      RETURN FALSE;
    ELSE
      RETURN TRUE;
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      PKG_AUDIT.LOG_ERROR(LC_SVN_ID,
                          LV_PROC_NAME,
                          LV_COMMENT,
                          '',
                          $$PLSQL_UNIT,
                          $$PLSQL_LINE,
                          SQLCODE,
                          SQLERRM);
      IF LV_DEBUG_LVL > 0 THEN
        RAISE;
      END IF;
      RETURN FALSE;
  END IS_PARTITIONED_DB;

  PROCEDURE LOG_DEPLOY_INFO(P_NAME VARCHAR2, P_SVN_ID VARCHAR2) IS
  BEGIN
    LV_PROC_NAME := 'log_deploy_info';
    PKG_AUDIT.LOG_PKG_INIT(P_NAME, P_SVN_ID);
  EXCEPTION
    WHEN OTHERS THEN
      PKG_AUDIT.LOG_ERROR(LC_SVN_ID,
                          LV_PROC_NAME,
                          LV_COMMENT,
                          '',
                          $$PLSQL_UNIT,
                          $$PLSQL_LINE,
                          SQLCODE,
                          SQLERRM);
      IF LV_DEBUG_LVL > 0 THEN
        RAISE;
      END IF;
  END LOG_DEPLOY_INFO;

  PROCEDURE POP_CUST_SCHEMA_TAB IS
    N BINARY_INTEGER := 0;
  BEGIN
    LV_PROC_NAME := 'pop_cust_schema_tab';
    LV_COMMENT   := 'if the PL/SQL table has no records, initialize it';
    IF CUST_SCHEMA_TAB.COUNT = 0 THEN
      FOR CUST_SCHEMA_REC IN (SELECT OWNER
                                FROM ALL_OBJECTS
                               WHERE OBJECT_TYPE = 'TABLE'
                                 AND OBJECT_NAME = CUST_SCH_INDICATOR_TAB
                               ORDER BY 1) LOOP
        N := N + 1;
        CUST_SCHEMA_TAB(N) := CUST_SCHEMA_REC.OWNER;
      END LOOP;
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      PKG_AUDIT.LOG_ERROR(LC_SVN_ID,
                          LV_PROC_NAME,
                          LV_COMMENT,
                          '',
                          $$PLSQL_UNIT,
                          $$PLSQL_LINE,
                          SQLCODE,
                          SQLERRM);
      IF LV_DEBUG_LVL > 0 THEN
        RAISE;
      END IF;
  END POP_CUST_SCHEMA_TAB;

  PROCEDURE LIST_CUST_SCHEMAS IS
  BEGIN
    LV_PROC_NAME := 'list_cust_schemas';
    LV_COMMENT   := 'if the PL/SQL table has no records, initialize it';
    POP_CUST_SCHEMA_TAB;
    IF CUST_SCHEMA_TAB.COUNT = 0 THEN
      DBMS_OUTPUT.PUT_LINE('No customer schemas found !');
    ELSE
      LV_COMMENT := 'loop over PL/SQL table printing records';
      FOR I IN CUST_SCHEMA_TAB.FIRST .. CUST_SCHEMA_TAB.LAST LOOP
        DBMS_OUTPUT.PUT_LINE(CUST_SCHEMA_TAB(I));
      END LOOP;
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      PKG_AUDIT.LOG_ERROR(LC_SVN_ID,
                          LV_PROC_NAME,
                          LV_COMMENT,
                          '',
                          $$PLSQL_UNIT,
                          $$PLSQL_LINE,
                          SQLCODE,
                          SQLERRM);
      IF LV_DEBUG_LVL > 0 THEN
        RAISE;
      END IF;
  END LIST_CUST_SCHEMAS;

  /*  FUNCTION is_cust_facing_db RETURN BOOLEAN IS
    BEGIN
      lv_proc_name := 'is_cust_facing_db';
      RETURN TRUE;
    EXCEPTION
      WHEN OTHERS THEN
        pkg_audit.log_error(lc_svn_id, lv_proc_name, lv_comment, '', $$PLSQL_UNIT, $$PLSQL_LINE, SQLCODE, SQLERRM);
        RETURN TRUE;
    END is_cust_facing_db;
  
    FUNCTION conflicting_sessions(p_edition VARCHAR) RETURN INTEGER IS
      v_sessions INTEGER;
    BEGIN
      lv_proc_name := 'conflicting_sessions';
      SELECT COUNT(*)
        INTO v_sessions
        FROM sys.gv_$session s
        LEFT OUTER JOIN sys.dba_objects o ON (s.session_edition_id = o.object_id)
       WHERE s.status <> 'KILLED' AND o.object_name = p_edition;
      RETURN v_sessions;
    EXCEPTION
      WHEN OTHERS THEN
        pkg_audit.log_error(lc_svn_id, lv_proc_name, lv_comment, '', $$PLSQL_UNIT, $$PLSQL_LINE, SQLCODE, SQLERRM);
        RETURN 1;
    END conflicting_sessions;
  
    FUNCTION using_default_edition RETURN BOOLEAN IS
      v_def_edition VARCHAR2(32);
    BEGIN
      lv_proc_name := 'using_default_edition';
      SELECT edition_name
        INTO v_def_edition
        FROM dba_editions e
        JOIN database_properties dp ON (dp.property_name = 'DEFAULT_EDITION' AND
                                       dp.property_value = e.edition_name);
      IF (sys_context('USERENV', 'CURRENT_EDITION_NAME') = v_def_edition) THEN
        RETURN TRUE;
      ELSE
        RETURN FALSE;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        pkg_audit.log_error(lc_svn_id, lv_proc_name, lv_comment, '', $$PLSQL_UNIT, $$PLSQL_LINE, SQLCODE, SQLERRM);
        RETURN TRUE;
    END using_default_edition;
  
    FUNCTION deploy_enabled RETURN BOOLEAN IS
    BEGIN
      lv_proc_name := 'deploy_enabled';
      IF (is_cust_facing_db AND using_default_edition) THEN
        RETURN FALSE;
      ELSE
        RETURN TRUE;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        pkg_audit.log_error(lc_svn_id, lv_proc_name, lv_comment, '', $$PLSQL_UNIT, $$PLSQL_LINE, SQLCODE, SQLERRM);
        RETURN FALSE;
    END deploy_enabled;
  
    -- Creates any missing synonyms for the user that called it. Uses invoker right and the all_objects view
    PROCEDURE fix_synonyms_for_user IS
    BEGIN
      lv_proc_name := 'fix_synonyms_for_user';
      FOR crec IN (SELECT MIN(owner) owner, object_name NAME
                     FROM all_objects
                    WHERE object_name IN (SELECT object_name NAME
                                            FROM all_objects
                                           WHERE owner <> sys_context('USERENV', 'SESSION_USER') AND
                                                 owner NOT LIKE '%SYS%' AND
                                                 owner NOT IN
                                                 ('OUTLN', 'DBSNMP', 'XDB', 'ORDDATA', 'PUBLIC', 'SI_INFORMTN_SCHEMA', 'MDDATA', 'OMS', 'XS$NULL') AND
                                                 object_type IN
                                                 ('PROCEDURE', 'VIEW', 'FUNCTION', 'MATERIALIZED VIEW', 'PACKAGE', 'SEQUENCE', 'TABLE', 'TYPE')
                                          MINUS
                                          SELECT synonym_name
                                            FROM user_synonyms) AND
                          owner <> sys_context('USERENV', 'SESSION_USER') AND owner NOT LIKE '%SYS%' AND
                          owner NOT IN
                          ('OUTLN', 'DBSNMP', 'XDB', 'ORDDATA', 'PUBLIC', 'SI_INFORMTN_SCHEMA', 'MDDATA', 'OMS', 'XS$NULL') AND
                          object_type IN
                          ('PROCEDURE', 'VIEW', 'FUNCTION', 'MATERIALIZED VIEW', 'PACKAGE', 'SEQUENCE', 'TABLE', 'TYPE')
                    GROUP BY object_name)
      LOOP
        BEGIN
          EXECUTE IMMEDIATE 'create synonym ' || crec.name || ' for ' || crec.owner || '.' ||
                            crec.name;
        EXCEPTION
          WHEN OTHERS THEN
            pkg_audit.log_error(lc_svn_id, lv_proc_name, lv_comment, '', $$PLSQL_UNIT, $$PLSQL_LINE, SQLCODE, SQLERRM);
        END;
      END LOOP;
    EXCEPTION
      WHEN OTHERS THEN
        pkg_audit.log_error(lc_svn_id, lv_proc_name, lv_comment, '', $$PLSQL_UNIT, $$PLSQL_LINE, SQLCODE, SQLERRM);
    END fix_synonyms_for_user;
  
    -- Creates any missing synonyms for the user specified.
    PROCEDURE fix_synonyms_for_user(p_username VARCHAR) IS
    BEGIN
      lv_proc_name := 'fix_synonyms_for_user';
      FOR crec IN ((SELECT r.grantee, p.owner, p.table_name
                      FROM dba_role_privs r
                      JOIN dba_tab_privs p ON (p.grantee = r.granted_role)
                     WHERE r.grantee = p_username
                    UNION
                    SELECT grantee, owner, table_name
                      FROM dba_tab_privs
                     WHERE grantee = p_username) MINUS SELECT owner, table_owner, table_name FROM
                   dba_synonyms WHERE owner = p_username)
      LOOP
        BEGIN
          EXECUTE IMMEDIATE 'create or replace synonym ' || crec.grantee || '.' || crec.table_name ||
                            ' for ' || crec.owner || '.' || crec.table_name;
        EXCEPTION
          WHEN OTHERS THEN
            NULL;
        END;
      END LOOP;
    EXCEPTION
      WHEN OTHERS THEN
        pkg_audit.log_error(lc_svn_id, lv_proc_name, lv_comment, p_username, $$PLSQL_UNIT, $$PLSQL_LINE, SQLCODE, SQLERRM);
    END fix_synonyms_for_user;
  
    -- Creates any missing synonyms for all users.
    PROCEDURE fix_synonyms_for_all_users IS
    BEGIN
      lv_proc_name := 'fix_synonyms_for_all_users';
      FOR crec IN (SELECT username
                     FROM dba_users
                    WHERE username NOT LIKE '%SYS%' AND
                          username NOT IN
                          ('OUTLN', 'DBSNMP', 'XDB', 'ORDDATA', 'PUBLIC', 'SI_INFORMTN_SCHEMA', 'MDDATA', 'OMS', 'XS$NULL'))
      LOOP
        fix_synonyms_for_user(crec.username);
      END LOOP;
    EXCEPTION
      WHEN OTHERS THEN
        pkg_audit.log_error(lc_svn_id, lv_proc_name, lv_comment, '', $$PLSQL_UNIT, $$PLSQL_LINE, SQLCODE, SQLERRM);
    END fix_synonyms_for_all_users;
  
    PROCEDURE create_synonyms(p_obj_owner VARCHAR, p_obj_name VARCHAR) IS
    BEGIN
      lv_proc_name := 'create_synonyms';
      FOR crec IN (SELECT username
                     FROM dba_users
                    WHERE username NOT LIKE '%SYS%' AND
                          username NOT IN
                          ('OUTLN', 'DBSNMP', 'XDB', 'ORDDATA', 'PUBLIC', 'SI_INFORMTN_SCHEMA', 'MDDATA', 'OMS', 'XS$NULL') AND
                          username <> p_obj_owner
                    ORDER BY username)
      LOOP
        BEGIN
          EXECUTE IMMEDIATE 'create or replace synonym ' || crec.username || '.' || p_obj_name ||
                            ' for ' || p_obj_owner || '.' || p_obj_name;
        EXCEPTION
          WHEN OTHERS THEN
            NULL;
        END;
      END LOOP;
    EXCEPTION
      WHEN OTHERS THEN
        pkg_audit.log_error(lc_svn_id, lv_proc_name, lv_comment, p_obj_owner || '.' ||
                                     p_obj_name, $$PLSQL_UNIT, $$PLSQL_LINE, SQLCODE, SQLERRM);
    END create_synonyms;
  
    PROCEDURE synonyms_grants(p_obj_owner VARCHAR,
                              p_obj_name  VARCHAR,
                              p_obj_type  VARCHAR DEFAULT 'PACKAGE',
                              p_project   VARCHAR DEFAULT NULL) IS
      v_role_name VARCHAR2(35);
    BEGIN
      lv_proc_name := 'synonyms_grants';
      lv_comment   := 'Creating synonyms';
      create_synonyms(p_obj_owner, p_obj_name);
      lv_comment := 'Check Project';
      IF (p_project IS NOT NULL) THEN
        SELECT ', ' || role
          INTO v_role_name
          FROM sys.dba_roles
         WHERE role = upper(p_project) || '_ROLE';
      END IF;
      lv_comment := 'Making grants';
    EXCEPTION
      WHEN OTHERS THEN
        pkg_audit.log_error(lc_svn_id, lv_proc_name, lv_comment, p_obj_type || ' ' ||
                                     p_obj_owner || '.' ||
                                     p_obj_name, $$PLSQL_UNIT, $$PLSQL_LINE, SQLCODE, SQLERRM);
    END synonyms_grants;
  */
  -- Example for p_update_sql: 'UPDATE /*+ ROWID (dda) */ order_items_ SET unit_amount_new = unit_amount WHERE rowid BETWEEN :start_id AND :end_id and unit_amount_new IS NULL';
  PROCEDURE UPDATE_ROWS(P_TABLE_OWNER VARCHAR,
                        P_TABLE_NAME  VARCHAR,
                        P_UPDATE_SQL  VARCHAR,
                        P_CHUNK_SIZE  PLS_INTEGER DEFAULT 5000) IS
    L_CHUNK_ID    NUMBER;
    L_START_ROWID ROWID;
    L_END_ROWID   ROWID;
    L_ANY_ROWS    BOOLEAN;
    L_ROW_COUNT   NUMBER;
  BEGIN
    LV_PROC_NAME := 'update_rows';
    LV_COMMENT   := 'Report runtime parameters';
    DBMS_APPLICATION_INFO.SET_MODULE(LV_PROC_NAME, P_TABLE_NAME);
    DBMS_APPLICATION_INFO.SET_CLIENT_INFO('Starting up');
    LV_COMMENT := 'Check for an existing task';
    SELECT COUNT(*)
      INTO L_ROW_COUNT
      FROM SYS.DBA_PARALLEL_EXECUTE_TASKS
     WHERE TASK_NAME = P_TABLE_NAME;
    IF (L_ROW_COUNT > 0) THEN
      LV_COMMENT := 'Drop the existing task';
      BEGIN
        DBMS_PARALLEL_EXECUTE.DROP_TASK(P_TABLE_NAME);
      EXCEPTION
        WHEN OTHERS THEN
          NULL;
      END;
    END IF;
    -- Create the Objects, task, and chunk by ROWID
    DBMS_PARALLEL_EXECUTE.CREATE_TASK(P_TABLE_NAME);
    DBMS_PARALLEL_EXECUTE.CREATE_CHUNKS_BY_ROWID(P_TABLE_NAME,
                                                 P_TABLE_OWNER,
                                                 P_TABLE_NAME,
                                                 TRUE,
                                                 P_CHUNK_SIZE);
    -- Process each chunk and commit.
    LOOP
      -- Get a chunk to process; if there is nothing to process, then exit the loop;
      DBMS_PARALLEL_EXECUTE.GET_ROWID_CHUNK(P_TABLE_NAME,
                                            L_CHUNK_ID,
                                            L_START_ROWID,
                                            L_END_ROWID,
                                            L_ANY_ROWS);
      IF (L_ANY_ROWS = FALSE) THEN
        EXIT;
      END IF;
      -- The chunk is specified by start_id and end_id.
      -- Bind the start_id and end_id and then execute it
      --
      -- If no error occured, set the chunk status to PROCESSED.
      --
      -- Catch any exception. If an exception occured, store the error num/msg
      -- into the chunk table and then continue to process the next chunk.
      --
      BEGIN
        EXECUTE IMMEDIATE P_UPDATE_SQL
          USING L_START_ROWID, L_END_ROWID;
        DBMS_PARALLEL_EXECUTE.SET_CHUNK_STATUS(P_TABLE_NAME,
                                               L_CHUNK_ID,
                                               DBMS_PARALLEL_EXECUTE.PROCESSED);
        COMMIT;
      EXCEPTION
        WHEN OTHERS THEN
          DBMS_PARALLEL_EXECUTE.SET_CHUNK_STATUS(P_TABLE_NAME,
                                                 L_CHUNK_ID,
                                                 DBMS_PARALLEL_EXECUTE.PROCESSED_WITH_ERROR,
                                                 SQLCODE,
                                                 SQLERRM);
      END;
    END LOOP;
  EXCEPTION
    WHEN OTHERS THEN
      PKG_AUDIT.LOG_ERROR(LC_SVN_ID,
                          LV_PROC_NAME,
                          LV_COMMENT,
                          '',
                          $$PLSQL_UNIT,
                          $$PLSQL_LINE,
                          SQLCODE,
                          SQLERRM);
      IF LV_DEBUG_LVL > 0 THEN
        RAISE;
      END IF;
  END UPDATE_ROWS;

  PROCEDURE DEPLOY_NEW_SCHEMA(P_TICKET  VARCHAR,
                              P_SCHEMA  VARCHAR,
                              P_COMMENT VARCHAR DEFAULT NULL) IS
    V_EXISTS PLS_INTEGER;
  BEGIN
    LV_PROC_NAME := 'deploy_new_schema';
    LV_COMMENT   := 'Checking if it already exists';
    SELECT COUNT(*)
      INTO V_EXISTS
      FROM ALL_USERS
     WHERE USERNAME = UPPER(P_SCHEMA);
    IF (V_EXISTS = 0) THEN
      LV_COMMENT := 'Creating';
      EXECUTE IMMEDIATE 'CREATE USER ' || P_SCHEMA ||
                        ' IDENTIFIED BY "D(FB2346----32DF" DEFAULT TABLESPACE DATA1 QUOTA UNLIMITED ON DATA1 ENABLE EDITIONS ACCOUNT LOCK';
      LV_COMMENT := 'Logging change';
      PKG_AUDIT.LOG_DDL_CHANGE(NULL,
                               P_SCHEMA,
                               'SCHEMA',
                               NULL,
                               P_TICKET,
                               NULL,
                               P_COMMENT,
                               LC_SVN_ID);
      BEGIN
        EXECUTE IMMEDIATE 'GRANT RESOURCE TO ' || P_SCHEMA;
      EXCEPTION
        WHEN OTHERS THEN
          PKG_AUDIT.LOG_ERROR(LC_SVN_ID,
                              LV_PROC_NAME,
                              LV_COMMENT,
                              P_TICKET || ' ' || P_SCHEMA,
                              $$PLSQL_UNIT,
                              $$PLSQL_LINE,
                              SQLCODE,
                              SQLERRM);
      END;
      BEGIN
        EXECUTE IMMEDIATE 'REVOKE CONNECT FROM ' || P_SCHEMA;
      EXCEPTION
        WHEN OTHERS THEN
          PKG_AUDIT.LOG_ERROR(LC_SVN_ID,
                              LV_PROC_NAME,
                              LV_COMMENT,
                              P_TICKET,
                              $$PLSQL_UNIT,
                              $$PLSQL_LINE,
                              SQLCODE,
                              SQLERRM);
      END;
      IF LV_DEBUG_LVL > 5 THEN
        DBMS_OUTPUT.PUT_LINE('INFO: Schema ' || P_SCHEMA ||
                             ' created for ' || P_TICKET);
      END IF;
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      PKG_AUDIT.LOG_ERROR(LC_SVN_ID,
                          LV_PROC_NAME,
                          LV_COMMENT,
                          P_TICKET,
                          $$PLSQL_UNIT,
                          $$PLSQL_LINE,
                          SQLCODE,
                          SQLERRM);
      IF LV_DEBUG_LVL > 0 THEN
        RAISE;
      END IF;
  END DEPLOY_NEW_SCHEMA;

  PROCEDURE DEPLOY_NEW_TABLE(P_TICKET          VARCHAR,
                             P_TABLE_OWNER     VARCHAR,
                             P_TABLE_NAME      VARCHAR,
                             P_SQL             VARCHAR,
                             P_PARTITIONED_SQL VARCHAR DEFAULT NULL,
                             P_COMMENT         VARCHAR DEFAULT NULL) IS
    V_EXISTS PLS_INTEGER;
  BEGIN
    LV_PROC_NAME := 'deploy_new_table';
    LV_COMMENT   := 'Checking if it already exists';
    SELECT COUNT(*)
      INTO V_EXISTS
      FROM ALL_TABLES
     WHERE OWNER = UPPER(P_TABLE_OWNER)
       AND TABLE_NAME = UPPER(P_TABLE_NAME);
    IF (V_EXISTS = 0) THEN
      LV_COMMENT := 'Creating table';
      IF (P_PARTITIONED_SQL IS NOT NULL) AND IS_PARTITIONED_DB THEN
        EXECUTE IMMEDIATE P_PARTITIONED_SQL;
        LV_COMMENT := 'Logging create partitioned table';
        PKG_AUDIT.LOG_DDL_CHANGE(P_TABLE_OWNER,
                                 P_TABLE_NAME,
                                 'TABLE',
                                 P_TABLE_OWNER,
                                 P_TICKET,
                                 P_PARTITIONED_SQL,
                                 P_COMMENT,
                                 LC_SVN_ID);
      ELSE
        EXECUTE IMMEDIATE P_SQL;
        LV_COMMENT := 'Logging create table';
        PKG_AUDIT.LOG_DDL_CHANGE(P_TABLE_OWNER,
                                 P_TABLE_NAME,
                                 'TABLE',
                                 P_TABLE_OWNER,
                                 P_TICKET,
                                 P_SQL,
                                 P_COMMENT,
                                 LC_SVN_ID);
      END IF;
      IF (P_COMMENT IS NOT NULL) THEN
        LV_COMMENT := 'Adding comment:' || P_COMMENT;
        EXECUTE IMMEDIATE 'comment on table ' || P_TABLE_OWNER || '.' ||
                          P_TABLE_NAME || ' is ''' || P_COMMENT || '''';
      END IF;
      IF LV_DEBUG_LVL > 5 THEN
        DBMS_OUTPUT.PUT_LINE('INFO: Table ' || P_TABLE_OWNER || '.' ||
                             P_TABLE_NAME || ' created for ' || P_TICKET);
      END IF;
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      PKG_AUDIT.LOG_ERROR(LC_SVN_ID,
                          LV_PROC_NAME,
                          LV_COMMENT,
                          P_TICKET || ' ' || P_TABLE_OWNER || ' ' ||
                          P_TABLE_NAME,
                          $$PLSQL_UNIT,
                          $$PLSQL_LINE,
                          SQLCODE,
                          SQLERRM);
      IF LV_DEBUG_LVL > 0 THEN
        RAISE;
      END IF;
  END DEPLOY_NEW_TABLE;

  PROCEDURE DEPLOY_NEW_COLUMN(P_TICKET      VARCHAR,
                              P_TABLE_OWNER VARCHAR,
                              P_TABLE_NAME  VARCHAR,
                              P_COL_NAME    VARCHAR,
                              P_SQL         VARCHAR,
                              P_COMMENT     VARCHAR DEFAULT NULL) IS
    V_EXISTS PLS_INTEGER;
  BEGIN
    LV_PROC_NAME := 'deploy_new_column';
    LV_COMMENT   := 'Checking if it already exists';
    SELECT COUNT(*)
      INTO V_EXISTS
      FROM ALL_TAB_COLS
     WHERE OWNER = UPPER(P_TABLE_OWNER)
       AND TABLE_NAME = UPPER(P_TABLE_NAME)
       AND COLUMN_NAME = UPPER(P_COL_NAME);
    IF (V_EXISTS = 0) THEN
      LV_COMMENT := 'Creating';
      EXECUTE IMMEDIATE P_SQL;
      LV_COMMENT := 'Logging change';
      PKG_AUDIT.LOG_DDL_CHANGE(P_TABLE_OWNER,
                               P_COL_NAME,
                               'COLUMN',
                               P_TABLE_NAME,
                               P_TICKET,
                               P_SQL,
                               P_COMMENT,
                               LC_SVN_ID);
      IF (P_COMMENT IS NOT NULL) THEN
        LV_COMMENT := 'Adding comment';
        EXECUTE IMMEDIATE 'comment on column ' || P_TABLE_OWNER || '.' ||
                          P_TABLE_NAME || '.' || P_COL_NAME || ' is ''' ||
                          P_COMMENT || '''';
      END IF;
      IF LV_DEBUG_LVL > 5 THEN
        DBMS_OUTPUT.PUT_LINE('INFO: Column ' || P_COL_NAME ||
                             ' added to table ' || P_TABLE_OWNER || '.' ||
                             P_TABLE_NAME || ' for ' || P_TICKET);
      END IF;
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      PKG_AUDIT.LOG_ERROR(LC_SVN_ID,
                          LV_PROC_NAME,
                          LV_COMMENT,
                          P_TICKET || ' ' || P_TABLE_OWNER || ' ' ||
                          P_TABLE_NAME || ' ' || P_COL_NAME,
                          $$PLSQL_UNIT,
                          $$PLSQL_LINE,
                          SQLCODE,
                          SQLERRM);
      IF LV_DEBUG_LVL > 0 THEN
        RAISE;
      END IF;
  END DEPLOY_NEW_COLUMN;

  PROCEDURE DEPLOY_NEW_INDEX(P_TICKET          VARCHAR,
                             P_TABLE_OWNER     VARCHAR,
                             P_TABLE_NAME      VARCHAR,
                             P_INDEX_NAME      VARCHAR,
                             P_SQL             VARCHAR,
                             P_PARTITIONED_SQL VARCHAR DEFAULT NULL,
                             P_COMMENT         VARCHAR DEFAULT NULL) IS
    V_EXISTS PLS_INTEGER;
  BEGIN
    LV_PROC_NAME := 'deploy_new_index';
    LV_COMMENT   := 'Checking if it already exists';
    SELECT COUNT(*)
      INTO V_EXISTS
      FROM ALL_INDEXES
     WHERE OWNER = UPPER(P_TABLE_OWNER)
       AND TABLE_NAME = UPPER(P_TABLE_NAME)
       AND INDEX_NAME = UPPER(P_INDEX_NAME);
    IF (V_EXISTS = 0) THEN
      LV_COMMENT := 'Creating';
      IF (P_PARTITIONED_SQL IS NOT NULL) AND IS_PARTITIONED_DB THEN
        EXECUTE IMMEDIATE P_PARTITIONED_SQL;
        LV_COMMENT := 'Logging create partitioned index';
        PKG_AUDIT.LOG_DDL_CHANGE(P_TABLE_OWNER,
                                 P_INDEX_NAME,
                                 'INDEX',
                                 P_TABLE_NAME,
                                 P_TICKET,
                                 P_PARTITIONED_SQL,
                                 P_COMMENT,
                                 LC_SVN_ID);
      ELSE
        EXECUTE IMMEDIATE P_SQL;
        LV_COMMENT := 'Logging create index';
        PKG_AUDIT.LOG_DDL_CHANGE(P_TABLE_OWNER,
                                 P_INDEX_NAME,
                                 'INDEX',
                                 P_TABLE_NAME,
                                 P_TICKET,
                                 P_SQL,
                                 P_COMMENT,
                                 LC_SVN_ID);
      END IF;
      IF LV_DEBUG_LVL > 5 THEN
        DBMS_OUTPUT.PUT_LINE('INFO: Index ' || P_INDEX_NAME ||
                             ' added to table ' || P_TABLE_OWNER || '.' ||
                             P_TABLE_NAME || ' for ' || P_TICKET);
      END IF;
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      PKG_AUDIT.LOG_ERROR(LC_SVN_ID,
                          LV_PROC_NAME,
                          LV_COMMENT,
                          P_TICKET || ' ' || P_TABLE_OWNER || ' ' ||
                          P_TABLE_NAME || ' ' || P_INDEX_NAME,
                          $$PLSQL_UNIT,
                          $$PLSQL_LINE,
                          SQLCODE,
                          SQLERRM);
      IF LV_DEBUG_LVL > 0 THEN
        RAISE;
      END IF;
  END DEPLOY_NEW_INDEX;

  PROCEDURE DEPLOY_NEW_SEQUENCE(P_TICKET   VARCHAR,
                                P_OWNER    VARCHAR,
                                P_SEQ_NAME VARCHAR,
                                P_SQL      VARCHAR DEFAULT NULL,
                                P_COMMENT  VARCHAR DEFAULT NULL) IS
    V_EXISTS PLS_INTEGER;
    V_SQL    VARCHAR2(200);
  BEGIN
    LV_PROC_NAME := 'deploy_new_sequence';
    LV_COMMENT   := 'Checking if it already exists';
    SELECT COUNT(*)
      INTO V_EXISTS
      FROM ALL_SEQUENCES
     WHERE SEQUENCE_OWNER = UPPER(P_OWNER)
       AND SEQUENCE_NAME = UPPER(P_SEQ_NAME);
    IF (V_EXISTS = 0) THEN
      LV_COMMENT := 'Creating';
      V_SQL      := P_SQL;
      IF P_SQL IS NULL THEN
        V_SQL := 'CREATE SEQUENCE ' || P_OWNER || '.' || P_SEQ_NAME ||
                 ' NOCACHE';
      END IF;
      EXECUTE IMMEDIATE V_SQL;
      LV_COMMENT := 'Logging change';
      PKG_AUDIT.LOG_DDL_CHANGE(P_OWNER,
                               P_SEQ_NAME,
                               'SEQUENCE',
                               NULL,
                               P_TICKET,
                               V_SQL,
                               P_COMMENT,
                               LC_SVN_ID);
      IF LV_DEBUG_LVL > 5 THEN
        DBMS_OUTPUT.PUT_LINE('INFO: Sequence ' || P_OWNER || '.' ||
                             P_SEQ_NAME || ' created for ' || P_TICKET);
      END IF;
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      PKG_AUDIT.LOG_ERROR(LC_SVN_ID,
                          LV_PROC_NAME,
                          LV_COMMENT,
                          P_TICKET || ' ' || P_OWNER || ' ' || P_SEQ_NAME,
                          $$PLSQL_UNIT,
                          $$PLSQL_LINE,
                          SQLCODE,
                          SQLERRM);
      IF LV_DEBUG_LVL > 0 THEN
        RAISE;
      END IF;
  END DEPLOY_NEW_SEQUENCE;

  -- This creates a sequence in the "cust_seq_schema" schema and then makes select grants to all customer schemas
  -- Passing the create DDL is optional, but if you do, be sure to specify "cust_seq_schema" as the schema
  PROCEDURE DEPLOY_NEW_SEQUENCE_CUST(P_TICKET   VARCHAR,
                                     P_SEQ_NAME VARCHAR,
                                     P_SQL      VARCHAR DEFAULT NULL,
                                     P_COMMENT  VARCHAR DEFAULT NULL) IS
  BEGIN
    LV_PROC_NAME := 'deploy_new_sequence_cust';
    LV_COMMENT   := 'Create sequence in ' || CUST_SEQ_SCHEMA || ' schema';
    DEPLOY_NEW_SEQUENCE(P_TICKET,
                        CUST_SEQ_SCHEMA,
                        P_SEQ_NAME,
                        P_SQL,
                        P_COMMENT);
    LV_COMMENT := 'Make grants to all cust schemas';
    POP_CUST_SCHEMA_TAB;
    IF CUST_SCHEMA_TAB.COUNT > 0 THEN
      LV_COMMENT := 'Loop over PL/SQL table - granting access';
      FOR I IN CUST_SCHEMA_TAB.FIRST .. CUST_SCHEMA_TAB.LAST LOOP
        LV_COMMENT := 'GRANT SELECT ON ' || CUST_SEQ_SCHEMA || '.' ||
                      P_SEQ_NAME || ' TO ' || CUST_SCHEMA_TAB(I);
        EXECUTE IMMEDIATE 'GRANT SELECT ON ' || CUST_SEQ_SCHEMA || '.' ||
                          P_SEQ_NAME || ' TO ' || CUST_SCHEMA_TAB(I);
      END LOOP;
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      PKG_AUDIT.LOG_ERROR(LC_SVN_ID,
                          LV_PROC_NAME,
                          LV_COMMENT,
                          P_TICKET || ' ' || CUST_SEQ_SCHEMA || ' ' ||
                          P_SEQ_NAME,
                          $$PLSQL_UNIT,
                          $$PLSQL_LINE,
                          SQLCODE,
                          SQLERRM);
      IF LV_DEBUG_LVL > 0 THEN
        RAISE;
      END IF;
  END DEPLOY_NEW_SEQUENCE_CUST;

  PROCEDURE DEPLOY_NEW_CONSTRAINT(P_TICKET          VARCHAR,
                                  P_TABLE_OWNER     VARCHAR,
                                  P_TABLE_NAME      VARCHAR,
                                  P_CONSTRAINT_NAME VARCHAR,
                                  P_SQL             VARCHAR,
                                  P_COMMENT         VARCHAR DEFAULT NULL) IS
    V_EXISTS PLS_INTEGER;
  BEGIN
    LV_PROC_NAME := 'deploy_new_constraint';
    LV_COMMENT   := 'Checking if it already exists';
    SELECT COUNT(*)
      INTO V_EXISTS
      FROM ALL_CONSTRAINTS
     WHERE OWNER = UPPER(P_TABLE_OWNER)
       AND TABLE_NAME = UPPER(P_TABLE_NAME)
       AND CONSTRAINT_NAME = UPPER(P_CONSTRAINT_NAME);
    IF (V_EXISTS = 0) THEN
      LV_COMMENT := 'Creating';
      EXECUTE IMMEDIATE P_SQL;
      LV_COMMENT := 'Logging change';
      PKG_AUDIT.LOG_DDL_CHANGE(P_TABLE_OWNER,
                               P_CONSTRAINT_NAME,
                               'CONSTRAINT',
                               P_TABLE_NAME,
                               P_TICKET,
                               P_SQL,
                               P_COMMENT,
                               LC_SVN_ID);
      IF LV_DEBUG_LVL > 5 THEN
        DBMS_OUTPUT.PUT_LINE('INFO: Constraint ' || P_CONSTRAINT_NAME ||
                             ' added to table ' || P_TABLE_OWNER || '.' ||
                             P_TABLE_NAME || ' for ' || P_TICKET);
      END IF;
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      PKG_AUDIT.LOG_ERROR(LC_SVN_ID,
                          LV_PROC_NAME,
                          LV_COMMENT,
                          P_TICKET || ' ' || P_TABLE_OWNER || ' ' ||
                          P_TABLE_NAME || ' ' || P_CONSTRAINT_NAME,
                          $$PLSQL_UNIT,
                          $$PLSQL_LINE,
                          SQLCODE,
                          SQLERRM);
      IF LV_DEBUG_LVL > 0 THEN
        RAISE;
      END IF;
  END DEPLOY_NEW_CONSTRAINT;

  PROCEDURE DEPLOY_NEW_JOB(P_TICKET   VARCHAR,
                           P_OWNER    VARCHAR,
                           P_JOB_NAME VARCHAR,
                           P_SQL      VARCHAR,
                           P_COMMENT  VARCHAR DEFAULT NULL) IS
    V_EXISTS PLS_INTEGER;
  BEGIN
    LV_PROC_NAME := 'deploy_new_job';
    LV_COMMENT   := 'Checking if the job already exists';
    SELECT COUNT(*)
      INTO V_EXISTS
      FROM SYS.DBA_SCHEDULER_JOBS
     WHERE OWNER = UPPER(P_OWNER)
       AND JOB_NAME = UPPER(P_JOB_NAME);
    IF (V_EXISTS = 0) THEN
      LV_COMMENT := 'Creating job';
      EXECUTE IMMEDIATE P_SQL;
      LV_COMMENT := 'Logging change';
      PKG_AUDIT.LOG_DDL_CHANGE(P_OWNER,
                               P_JOB_NAME,
                               'JOB',
                               NULL,
                               P_TICKET,
                               P_SQL,
                               P_COMMENT,
                               LC_SVN_ID);
      IF LV_DEBUG_LVL > 5 THEN
        DBMS_OUTPUT.PUT_LINE('INFO: Oracle Job ' || P_OWNER || '.' ||
                             P_JOB_NAME || ' created for ' || P_TICKET);
      END IF;
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      PKG_AUDIT.LOG_ERROR(LC_SVN_ID,
                          LV_PROC_NAME,
                          LV_COMMENT,
                          P_TICKET || ' ' || P_OWNER || ' ' || P_JOB_NAME,
                          $$PLSQL_UNIT,
                          $$PLSQL_LINE,
                          SQLCODE,
                          SQLERRM);
      IF LV_DEBUG_LVL > 0 THEN
        RAISE;
      END IF;
  END DEPLOY_NEW_JOB;

  PROCEDURE DEPLOY_ALTER_COLUMN(P_TICKET      VARCHAR,
                                P_TABLE_OWNER VARCHAR,
                                P_TABLE_NAME  VARCHAR,
                                P_COL_NAME    VARCHAR,
                                P_SQL         VARCHAR,
                                P_COMMENT     VARCHAR DEFAULT NULL) IS
    V_EXISTS PLS_INTEGER;
  BEGIN
    LV_PROC_NAME := 'deploy_alter_column';
    LV_COMMENT   := 'Checking if it already exists';
    SELECT COUNT(*)
      INTO V_EXISTS
      FROM ALL_TAB_COLS
     WHERE OWNER = UPPER(P_TABLE_OWNER)
       AND TABLE_NAME = UPPER(P_TABLE_NAME)
       AND COLUMN_NAME = UPPER(P_COL_NAME);
    IF (V_EXISTS = 1) THEN
      LV_COMMENT := 'Altering';
      EXECUTE IMMEDIATE P_SQL;
      LV_COMMENT := 'Logging change';
      PKG_AUDIT.LOG_DDL_CHANGE(P_TABLE_OWNER,
                               P_COL_NAME,
                               'COLUMN',
                               P_TABLE_NAME,
                               P_TICKET,
                               P_SQL,
                               P_COMMENT,
                               LC_SVN_ID);
      IF (P_COMMENT IS NOT NULL) THEN
        LV_COMMENT := 'Adding comment';
        EXECUTE IMMEDIATE 'comment on column ' || P_TABLE_OWNER || '.' ||
                          P_TABLE_NAME || '.' || P_COL_NAME || ' is ''' ||
                          P_COMMENT || '''';
      END IF;
      IF LV_DEBUG_LVL > 5 THEN
        DBMS_OUTPUT.PUT_LINE('INFO: Column ' || P_COL_NAME || ' on table ' ||
                             P_TABLE_OWNER || '.' || P_TABLE_NAME ||
                             ' altered for ' || P_TICKET);
      END IF;
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      PKG_AUDIT.LOG_ERROR(LC_SVN_ID,
                          LV_PROC_NAME,
                          LV_COMMENT,
                          P_TICKET || ' ' || P_TABLE_OWNER || ' ' ||
                          P_TABLE_NAME || ' ' || P_COL_NAME,
                          $$PLSQL_UNIT,
                          $$PLSQL_LINE,
                          SQLCODE,
                          SQLERRM);
      IF LV_DEBUG_LVL > 0 THEN
        RAISE;
      END IF;
  END DEPLOY_ALTER_COLUMN;

  PROCEDURE DEPLOY_DDL(P_TICKET  VARCHAR,
                       P_SQL     VARCHAR,
                       P_COMMENT VARCHAR DEFAULT NULL) IS
  BEGIN
    LV_PROC_NAME := 'deploy_ddl';
    EXECUTE IMMEDIATE P_SQL;
    PKG_AUDIT.LOG_DDL_CHANGE(NULL,
                             NULL,
                             NULL,
                             NULL,
                             P_TICKET,
                             P_SQL,
                             P_COMMENT,
                             LC_SVN_ID);
    IF LV_DEBUG_LVL > 5 THEN
      DBMS_OUTPUT.PUT_LINE('INFO: Generic DDL ' || P_SQL ||
                           ' performed for ' || P_TICKET);
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      PKG_AUDIT.LOG_ERROR(LC_SVN_ID,
                          LV_PROC_NAME,
                          LV_COMMENT,
                          P_TICKET,
                          $$PLSQL_UNIT,
                          $$PLSQL_LINE,
                          SQLCODE,
                          SQLERRM);
      IF LV_DEBUG_LVL > 0 THEN
        RAISE;
      END IF;
  END DEPLOY_DDL;

  PROCEDURE DROP_OBJECT(P_TICKET  VARCHAR,
                        P_TYPE    VARCHAR,
                        P_OWNER   VARCHAR,
                        P_NAME    VARCHAR,
                        P_SQL     VARCHAR DEFAULT NULL,
                        P_COMMENT VARCHAR DEFAULT NULL) IS
    L_CNT    PLS_INTEGER;
    L_PARENT VARCHAR2(100);
  BEGIN
    LV_PROC_NAME := 'drop_object';
    CASE P_TYPE
      WHEN 'JOB' THEN
        LV_COMMENT := 'Checking for existance of job';
        SELECT COUNT(*)
          INTO L_CNT
          FROM SYS.DBA_SCHEDULER_JOBS
         WHERE OWNER = UPPER(P_OWNER)
           AND JOB_NAME = UPPER(P_NAME);
        IF (L_CNT > 0) THEN
          LV_COMMENT := 'Dropping ' || P_NAME || ' job';
          SYS.DBMS_SCHEDULER.DROP_JOB(P_OWNER || '.' || P_NAME);
          LV_COMMENT := 'Logging change';
          PKG_AUDIT.LOG_DDL_CHANGE(P_OWNER,
                                   P_NAME,
                                   P_TYPE,
                                   NULL,
                                   P_TICKET,
                                   NULL,
                                   'Dropped: ' || P_COMMENT,
                                   LC_SVN_ID);
          IF LV_DEBUG_LVL > 5 THEN
            DBMS_OUTPUT.PUT_LINE('INFO: ' || P_TYPE || ' ' || P_OWNER || '.' ||
                                 P_NAME || ' dropped for ' || P_TICKET);
          END IF;
        END IF;
      WHEN 'CONSTRAINT' THEN
        LV_COMMENT := 'Checking for existance of constraint';
        SELECT COUNT(*)
          INTO L_CNT
          FROM ALL_CONSTRAINTS
         WHERE OWNER = UPPER(P_OWNER)
           AND CONSTRAINT_NAME = UPPER(P_NAME);
        IF (L_CNT > 0) THEN
          SELECT TABLE_NAME
            INTO L_PARENT
            FROM ALL_CONSTRAINTS
           WHERE OWNER = UPPER(P_OWNER)
             AND CONSTRAINT_NAME = UPPER(P_NAME);
          LV_COMMENT := 'Dropping ' || P_NAME || ' constraint';
          EXECUTE IMMEDIATE 'alter table ' || P_OWNER || '.' || L_PARENT ||
                            ' drop constraint ' || P_NAME;
          LV_COMMENT := 'Logging change';
          PKG_AUDIT.LOG_DDL_CHANGE(P_OWNER,
                                   P_NAME,
                                   P_TYPE,
                                   NULL,
                                   P_TICKET,
                                   NULL,
                                   'Dropped: ' || P_COMMENT,
                                   LC_SVN_ID);
          IF LV_DEBUG_LVL > 5 THEN
            DBMS_OUTPUT.PUT_LINE('INFO: ' || P_TYPE || ' ' || P_OWNER || '.' ||
                                 P_NAME || ' dropped for ' || P_TICKET);
          END IF;
        END IF;
      WHEN 'COLUMN' THEN
        LV_COMMENT := 'Checking for existance of column';
        SELECT COUNT(*)
          INTO L_CNT
          FROM ALL_TAB_COLS
         WHERE OWNER = UPPER(P_OWNER)
           AND COLUMN_NAME = UPPER(P_NAME);
        IF (L_CNT > 0) THEN
          SELECT TABLE_NAME
            INTO L_PARENT
            FROM ALL_TAB_COLS
           WHERE OWNER = UPPER(P_OWNER)
             AND COLUMN_NAME = UPPER(P_NAME);
          LV_COMMENT := 'Dropping ' || P_NAME || ' constraint';
          EXECUTE IMMEDIATE 'alter table ' || P_OWNER || '.' || L_PARENT ||
                            ' drop column ' || P_NAME;
          LV_COMMENT := 'Logging change';
          PKG_AUDIT.LOG_DDL_CHANGE(P_OWNER,
                                   P_NAME,
                                   P_TYPE,
                                   NULL,
                                   P_TICKET,
                                   NULL,
                                   'Dropped: ' || P_COMMENT,
                                   LC_SVN_ID);
          IF LV_DEBUG_LVL > 5 THEN
            DBMS_OUTPUT.PUT_LINE('INFO: ' || P_TYPE || ' ' || P_OWNER || '.' ||
                                 P_NAME || ' dropped for ' || P_TICKET);
          END IF;
        END IF;
      ELSE
        LV_COMMENT := 'Checking for existance';
        SELECT COUNT(*)
          INTO L_CNT
          FROM ALL_OBJECTS
         WHERE OBJECT_TYPE = UPPER(P_TYPE)
           AND OWNER = UPPER(P_OWNER)
           AND OBJECT_NAME = UPPER(P_NAME);
        IF (L_CNT > 0) THEN
          LV_COMMENT := 'Dropping';
          IF (P_SQL IS NULL) THEN
            EXECUTE IMMEDIATE 'drop ' || P_TYPE || ' ' || P_OWNER || '.' ||
                              P_NAME;
          ELSE
            EXECUTE IMMEDIATE P_SQL;
            LV_COMMENT := 'Logging change';
            PKG_AUDIT.LOG_DDL_CHANGE(P_OWNER,
                                     P_NAME,
                                     P_TYPE,
                                     NULL,
                                     P_TICKET,
                                     P_SQL,
                                     'Dropped: ' || P_COMMENT,
                                     LC_SVN_ID);
          END IF;
          IF LV_DEBUG_LVL > 5 THEN
            DBMS_OUTPUT.PUT_LINE('INFO: ' || P_TYPE || ' ' || P_OWNER || '.' ||
                                 P_NAME || ' dropped for ' || P_TICKET);
          END IF;
        END IF;
    END CASE;
  EXCEPTION
    WHEN OTHERS THEN
      PKG_AUDIT.LOG_ERROR(LC_SVN_ID,
                          LV_PROC_NAME,
                          LV_COMMENT,
                          P_TICKET || ' ' || P_TYPE || ' ' || P_OWNER || '.' ||
                          P_NAME,
                          $$PLSQL_UNIT,
                          $$PLSQL_LINE,
                          SQLCODE,
                          SQLERRM);
      IF LV_DEBUG_LVL > 0 THEN
        RAISE;
      END IF;
  END DROP_OBJECT;

  FUNCTION BACKUP_TABLE_NAME(P_TICKET      VARCHAR,
                             P_TABLE_OWNER VARCHAR,
                             P_TABLE_NAME  VARCHAR) RETURN VARCHAR IS
    V_NAME VARCHAR2(200);
    V_SIZE PLS_INTEGER;
  BEGIN
    LV_PROC_NAME := 'backup_table_name';
    LV_COMMENT   := 'Get length of the ticket string to append';
    V_SIZE       := LENGTH(P_TICKET);
    LV_COMMENT   := 'construct the name, making sure the ticket will fit in 30 chars and sub invalid chars';
    V_NAME       := REPLACE(SUBSTR(P_TABLE_OWNER || '_' || P_TABLE_NAME,
                                   1,
                                   29 - V_SIZE) || '_' || P_TICKET,
                            '-',
                            '_');
    LV_COMMENT   := 'return the first 30 chars';
    RETURN SUBSTR(V_NAME, 1, 30);
  EXCEPTION
    WHEN OTHERS THEN
      PKG_AUDIT.LOG_ERROR(LC_SVN_ID,
                          LV_PROC_NAME,
                          LV_COMMENT,
                          P_TICKET || ' ' || P_TABLE_OWNER || '.' ||
                          P_TABLE_NAME,
                          $$PLSQL_UNIT,
                          $$PLSQL_LINE,
                          SQLCODE,
                          SQLERRM);
      IF LV_DEBUG_LVL > 0 THEN
        RAISE;
      END IF;
  END BACKUP_TABLE_NAME;

  PROCEDURE BACKUP_TABLE_NAME(P_TICKET      VARCHAR,
                              P_TABLE_OWNER VARCHAR,
                              P_TABLE_NAME  VARCHAR) IS
    V_NAME VARCHAR2(200);
  BEGIN
    LV_PROC_NAME := 'backup_table_name';
    LV_COMMENT   := 'call backup_table_name function';
    V_NAME       := BACKUP_TABLE_NAME(P_TICKET, P_TABLE_OWNER, P_TABLE_NAME);
    LV_COMMENT   := 'print result';
    DBMS_OUTPUT.PUT_LINE(BACKUP_SCHEMA || '.' || V_NAME);
  EXCEPTION
    WHEN OTHERS THEN
      PKG_AUDIT.LOG_ERROR(LC_SVN_ID,
                          LV_PROC_NAME,
                          LV_COMMENT,
                          P_TICKET || ' ' || P_TABLE_OWNER || '.' ||
                          P_TABLE_NAME,
                          $$PLSQL_UNIT,
                          $$PLSQL_LINE,
                          SQLCODE,
                          SQLERRM);
      IF LV_DEBUG_LVL > 0 THEN
        RAISE;
      END IF;
  END BACKUP_TABLE_NAME;

  /* pkg_deploy_utils.backup_data
  This creates a backup copy of a table (or a subset of the table's rows)
  The resulting backup table name contains the ticket info and the originating schema (if needed)
  p_sql - optional select statement to only save some of the rows, default is "select *" from the table
    if using this on a table in the cust schemas, you must use 'MASTER_SCHEMA' as the table owner.
    This is replaced bythe correct schema name for each cust schema
  p_expire_date - specify a date the data can be removed, default is create time + 30 days
  p_comment - optional comment to describe how to use the data, or why it was saved
  
  Features:
  1. Details of this backup operation will be stored in the data_audit_log table.
  2. If p_table_owner is MASTER_SCHEMA, also perform a backup of all the cust schemas with this one call
  3. Create a function that accepts the same first 3 parameters and returns the name of the backup table
  4. Add expire date as comment on backup table
  */
  PROCEDURE BACKUP_DATA(P_TICKET      VARCHAR,
                        P_TABLE_OWNER VARCHAR,
                        P_TABLE_NAME  VARCHAR,
                        P_SQL         VARCHAR DEFAULT NULL,
                        P_EXPIRE_DATE DATE DEFAULT NULL,
                        P_COMMENT     VARCHAR DEFAULT NULL) IS
    V_SQL            VARCHAR2(32000);
    V_BKP_TABLE_NAME VARCHAR2(35);
    V_EXPIRE         VARCHAR2(35);
    V_COMMENT        VARCHAR2(4000);
  
    PROCEDURE BKP_1_TABLE(P_TICKET      VARCHAR,
                          P_TABLE_OWNER VARCHAR,
                          P_TABLE_NAME  VARCHAR,
                          P_SQL         VARCHAR DEFAULT NULL,
                          P_COMMENT     VARCHAR) IS
      V_CNT            PLS_INTEGER;
      V_SQL            VARCHAR2(32000);
      V_BKP_TABLE_NAME VARCHAR2(35);
    BEGIN
      LV_COMMENT := 'in bkp_1_table proc';
      IF P_SQL IS NULL THEN
        V_SQL := 'select * from ' || P_TABLE_OWNER || '.' || P_TABLE_NAME;
      ELSE
        V_SQL := REPLACE(P_SQL, 'MASTER_SCHEMA', P_TABLE_OWNER);
      END IF;
      LV_COMMENT := 'chk for existance of the source table';
      SELECT COUNT(*)
        INTO V_CNT
        FROM ALL_TABLES
       WHERE OWNER = P_TABLE_OWNER
         AND TABLE_NAME = P_TABLE_NAME;
      IF V_CNT = 1 THEN
        LV_COMMENT       := 'performing backup';
        V_BKP_TABLE_NAME := BACKUP_TABLE_NAME(P_TICKET,
                                              P_TABLE_OWNER,
                                              P_TABLE_NAME);
        LV_COMMENT       := 'chk for existance of the backup table';
        SELECT COUNT(*)
          INTO V_CNT
          FROM ALL_TABLES
         WHERE OWNER = BACKUP_SCHEMA
           AND TABLE_NAME = V_BKP_TABLE_NAME;
        IF V_CNT = 0 THEN
          LV_COMMENT := 'bkp_1_table - create table ' || BACKUP_SCHEMA || '.' ||
                        V_BKP_TABLE_NAME || ' as ' || V_SQL;
          EXECUTE IMMEDIATE 'create table ' || BACKUP_SCHEMA || '.' ||
                            V_BKP_TABLE_NAME || ' as ' || V_SQL;
          LV_COMMENT := 'bkp_1_table - comment on table ' || BACKUP_SCHEMA || '.' ||
                        V_BKP_TABLE_NAME || ' IS ''' || P_COMMENT || '''';
          EXECUTE IMMEDIATE 'comment on table ' || BACKUP_SCHEMA || '.' ||
                            V_BKP_TABLE_NAME || ' IS ''' || P_COMMENT || '''';
          LV_COMMENT := 'logging change';
          INSERT INTO DATA_AUDIT_LOG
            (LOG_DATE,
             USER_NAME,
             APP_NAME,
             TAB_OWNER,
             TAB_NAME,
             ACTION_TYPE,
             DML_TYPE,
             LOG_COMMENT)
          VALUES
            (SYSDATE,
             USER,
             'pkg_deploy_utils.backup_data',
             P_TABLE_OWNER,
             P_TABLE_NAME,
             'BACKUP',
             'CTAS',
             P_COMMENT);
          LV_COMMENT := 'Report change';
        END IF;
        IF LV_DEBUG_LVL > 5 THEN
          DBMS_OUTPUT.PUT_LINE('INFO: Table ' || P_TABLE_OWNER || '.' ||
                               P_TABLE_NAME || ' backed up for ' ||
                               P_TICKET);
        END IF;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        PKG_AUDIT.LOG_ERROR(LC_SVN_ID,
                            LV_PROC_NAME,
                            LV_COMMENT,
                            P_TICKET || ' ' || P_TABLE_OWNER || '.' ||
                            P_TABLE_NAME,
                            $$PLSQL_UNIT,
                            $$PLSQL_LINE,
                            SQLCODE,
                            SQLERRM);
    END BKP_1_TABLE;
  BEGIN
    LV_PROC_NAME := 'backup_data';
    LV_COMMENT   := 'computing expiration date';
    IF P_EXPIRE_DATE IS NULL THEN
      V_EXPIRE := TO_CHAR(SYSDATE + 30, 'DD-MON-YYYY');
    ELSE
      V_EXPIRE := TO_CHAR(P_EXPIRE_DATE, 'DD-MON-YYYY');
    END IF;
    LV_COMMENT := 'computing change comment';
    V_COMMENT  := SUBSTR(P_TICKET || ' Expires: ' || V_EXPIRE || ' ' ||
                         P_COMMENT,
                         1,
                         4000);
    LV_COMMENT := 'Checking if this goes to all cust schemas';
    IF P_TABLE_OWNER = 'MASTER_SCHEMA' THEN
      LV_COMMENT := 'if the PL/SQL table has no records, initialize it';
      POP_CUST_SCHEMA_TAB;
      LV_COMMENT := 'loop over all the cust schemas';
      FOR I IN CUST_SCHEMA_TAB.FIRST .. CUST_SCHEMA_TAB.LAST LOOP
        BKP_1_TABLE(P_TICKET,
                    CUST_SCHEMA_TAB(I),
                    P_TABLE_NAME,
                    P_SQL,
                    V_COMMENT);
      END LOOP;
    ELSE
      BKP_1_TABLE(P_TICKET, P_TABLE_OWNER, P_TABLE_NAME, P_SQL, V_COMMENT);
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      PKG_AUDIT.LOG_ERROR(LC_SVN_ID,
                          LV_PROC_NAME,
                          LV_COMMENT,
                          P_TICKET || ' ' || P_TABLE_OWNER || '.' ||
                          P_TABLE_NAME,
                          $$PLSQL_UNIT,
                          $$PLSQL_LINE,
                          SQLCODE,
                          SQLERRM);
      IF LV_DEBUG_LVL > 0 THEN
        RAISE;
      END IF;
  END BACKUP_DATA;

  -- trim_backup_data - trims the backup data if it is past it's expire date
  -- the force option ignores the expiration date and always drops the data
  PROCEDURE TRIM_BACKUP_DATA(P_TICKET      VARCHAR,
                             P_TABLE_OWNER VARCHAR,
                             P_TABLE_NAME  VARCHAR,
                             FORCE         BOOLEAN DEFAULT FALSE) IS
    V_BKP_TABLE_NAME VARCHAR2(35);
  
    PROCEDURE TRIM_1_TABLE(P_TICKET      VARCHAR,
                           P_TABLE_OWNER VARCHAR,
                           P_TABLE_NAME  VARCHAR,
                           FORCE         BOOLEAN DEFAULT FALSE) IS
      V_CNT            PLS_INTEGER;
      V_AGE            PLS_INTEGER;
      V_BKP_TABLE_NAME VARCHAR2(35);
      V_EXPIRED        BOOLEAN := FALSE;
    BEGIN
      LV_COMMENT := 'in trim_1_table proc';
      LV_COMMENT := 'chk for existance of the backup table';
      SELECT COUNT(*)
        INTO V_CNT
        FROM ALL_TABLES
       WHERE OWNER = BACKUP_SCHEMA
         AND TABLE_NAME = V_BKP_TABLE_NAME;
      IF V_CNT = 1 THEN
        LV_COMMENT := 'chk expiration status of the backup table';
        -- check here
        SELECT ROUND(SYSDATE - NVL(MAX(CREATED), SYSDATE))
          INTO V_AGE
          FROM ALL_OBJECTS
         WHERE OWNER = BACKUP_SCHEMA
           AND OBJECT_NAME = V_BKP_TABLE_NAME
           AND OBJECT_TYPE = 'TABLE';
        IF V_AGE > 30 THEN
          V_EXPIRED := TRUE;
        END IF;
        IF V_EXPIRED OR FORCE THEN
          EXECUTE IMMEDIATE 'drop table ' || BACKUP_SCHEMA || '.' ||
                            V_BKP_TABLE_NAME;
          LV_COMMENT := 'logging change';
          INSERT INTO DATA_AUDIT_LOG
            (LOG_DATE,
             USER_NAME,
             APP_NAME,
             TAB_OWNER,
             TAB_NAME,
             ACTION_TYPE,
             DML_TYPE,
             LOG_COMMENT)
          VALUES
            (SYSDATE,
             USER,
             'pkg_deploy_utils.trim_backup_data',
             P_TABLE_OWNER,
             P_TABLE_NAME,
             'TRIM',
             'DROP',
             '');
        END IF;
        IF LV_DEBUG_LVL > 5 THEN
          DBMS_OUTPUT.PUT_LINE('INFO: Backup data from ' || P_TABLE_OWNER || '.' ||
                               P_TABLE_NAME || ' trimd for ' || P_TICKET);
        END IF;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        PKG_AUDIT.LOG_ERROR(LC_SVN_ID,
                            LV_PROC_NAME,
                            LV_COMMENT,
                            P_TICKET || ' ' || P_TABLE_OWNER || '.' ||
                            P_TABLE_NAME,
                            $$PLSQL_UNIT,
                            $$PLSQL_LINE,
                            SQLCODE,
                            SQLERRM);
    END TRIM_1_TABLE;
  BEGIN
    LV_PROC_NAME := 'trim_backup_data';
    LV_COMMENT   := 'Checking if this goes to all cust schemas';
    IF P_TABLE_OWNER = 'MASTER_SCHEMA' THEN
      LV_COMMENT := 'if the PL/SQL table has no records, initialize it';
      POP_CUST_SCHEMA_TAB;
      LV_COMMENT := 'loop over all the cust schemas';
      FOR I IN CUST_SCHEMA_TAB.FIRST .. CUST_SCHEMA_TAB.LAST LOOP
        TRIM_1_TABLE(P_TICKET, CUST_SCHEMA_TAB(I), P_TABLE_NAME, FORCE);
      END LOOP;
    ELSE
      TRIM_1_TABLE(P_TICKET, P_TABLE_OWNER, P_TABLE_NAME, FORCE);
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      PKG_AUDIT.LOG_ERROR(LC_SVN_ID,
                          LV_PROC_NAME,
                          LV_COMMENT,
                          P_TICKET || ' ' || P_TABLE_OWNER || '.' ||
                          P_TABLE_NAME,
                          $$PLSQL_UNIT,
                          $$PLSQL_LINE,
                          SQLCODE,
                          SQLERRM);
      IF LV_DEBUG_LVL > 0 THEN
        RAISE;
      END IF;
  END TRIM_BACKUP_DATA;

BEGIN
  PKG_AUDIT.LOG_PKG_INIT($$PLSQL_UNIT, LC_SVN_ID);
END PKG_DEPLOY_UTILS;
/
