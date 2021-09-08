SET DEFINE OFF

CREATE OR REPLACE PACKAGE BODY dbadmin.deploy_utils
-- File $Id: deploy_utils_body.sql 4120 2014-04-21 15:11:42Z dheltzel $
-- Modified $Author: dheltzel $
-- Date $Date: 2014-04-21 11:11:42 -0400 (Mon, 21 Apr 2014) $
-- Revision $Revision: 4120 $
 AS
  lc_svn_id    VARCHAR2(200) := '$Id: deploy_utils_body.sql 4120 2014-04-21 15:11:42Z dheltzel $';
  lv_proc_name err_log.proc_name%TYPE;
  lv_comment   err_log.error_loc%TYPE := 'Starting';

  /* Set and get this with the get_set_debug_level proc below
    defaults to 10, which prints everything. Setting this to:
    0 - suppresses all the errors to the screen
    5 - suppresses informational "success" messages, this will reduce the noise in the logs to only failed operations
    Note: exceptions will ALWAYS be written to the err_log table, and every operation is recorded in the audit tables
  */
  lv_debug_lvl PLS_INTEGER := 10;

  PROCEDURE pkg_info IS
    v_edition VARCHAR2(35);
  BEGIN
    lv_proc_name := 'pkg_info';
    lv_comment   := 'Dumping deploy pkg info';
    dbms_output.put_line('$Revision: 4120 $');
    dbms_output.put_line('$Date: 2014-04-21 11:11:42 -0400 (Mon, 21 Apr 2014) $');
    dbms_output.put_line('$Author: dheltzel $');
    dbms_output.put_line('$Id: deploy_utils_body.sql 4120 2014-04-21 15:11:42Z dheltzel $');
    lv_comment := 'Getting the current edition';
    SELECT sys_context('USERENV', 'CURRENT_EDITION_NAME') INTO v_edition FROM dual;
    dbms_output.put_line('Edition: ' || v_edition);
    dbadmin.audit_pkg.log_error(lc_svn_id, lv_proc_name, lv_comment, v_edition, $$PLSQL_UNIT, $$PLSQL_LINE, SQLCODE, SQLERRM);
  EXCEPTION
    WHEN OTHERS THEN
      dbadmin.audit_pkg.log_error(lc_svn_id, lv_proc_name, lv_comment, v_edition, $$PLSQL_UNIT, $$PLSQL_LINE, SQLCODE, SQLERRM);
      IF lv_debug_lvl > 0 THEN
        RAISE;
      END IF;
  END pkg_info;

  -- Get and/or Set Debug Level
  FUNCTION get_set_debug_level(new_debug_lvl IN INTEGER DEFAULT NULL) RETURN INTEGER IS
  BEGIN
    IF new_debug_lvl IS NOT NULL THEN
      lv_debug_lvl := new_debug_lvl;
    END IF;
    RETURN(lv_debug_lvl);
  END get_set_debug_level;

  -- This will setup package variables and create an initial log entry for the deploy
  PROCEDURE initialize_deploy(p_ticket       VARCHAR,
                              p_release_name VARCHAR2,
                              p_svn_revision VARCHAR2,
                              p_svn_id       VARCHAR2) IS
  BEGIN
    lv_proc_name     := 'initialize_deploy';
    current_release  := p_release_name;
    current_revision := p_svn_revision;
    dbadmin.audit_pkg.log_ddl_change(p_release_name, p_svn_revision, 'DEPLOY', NULL, p_ticket, NULL, NULL, p_svn_id);
  EXCEPTION
    WHEN OTHERS THEN
      dbadmin.audit_pkg.log_error(lc_svn_id, lv_proc_name, lv_comment, '', $$PLSQL_UNIT, $$PLSQL_LINE, SQLCODE, SQLERRM);
      IF lv_debug_lvl > 0 THEN
        RAISE;
      END IF;
  END initialize_deploy;

  FUNCTION get_current_release RETURN VARCHAR2 IS
  BEGIN
    lv_proc_name := 'get_current_release';
    RETURN(current_release);
  EXCEPTION
    WHEN OTHERS THEN
      dbadmin.audit_pkg.log_error(lc_svn_id, lv_proc_name, lv_comment, '', $$PLSQL_UNIT, $$PLSQL_LINE, SQLCODE, SQLERRM);
      IF lv_debug_lvl > 0 THEN
        RAISE;
      END IF;
  END get_current_release;

  FUNCTION get_current_revision RETURN VARCHAR2 IS
  BEGIN
    lv_proc_name := 'get_current_revision';
    RETURN(current_revision);
  EXCEPTION
    WHEN OTHERS THEN
      dbadmin.audit_pkg.log_error(lc_svn_id, lv_proc_name, lv_comment, '', $$PLSQL_UNIT, $$PLSQL_LINE, SQLCODE, SQLERRM);
      IF lv_debug_lvl > 0 THEN
        RAISE;
      END IF;
  END get_current_revision;

  FUNCTION is_partitioned_db RETURN BOOLEAN IS
    l_value VARCHAR2(10);
  BEGIN
    lv_proc_name := 'is_partitioned_db';
    SELECT VALUE INTO l_value FROM v$option WHERE parameter = 'Partitioning';
    IF l_value = 'FALSE' THEN
      RETURN FALSE;
    ELSE
      RETURN TRUE;
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      dbadmin.audit_pkg.log_error(lc_svn_id, lv_proc_name, lv_comment, '', $$PLSQL_UNIT, $$PLSQL_LINE, SQLCODE, SQLERRM);
      IF lv_debug_lvl > 0 THEN
        RAISE;
      END IF;
      RETURN FALSE;
  END is_partitioned_db;

  PROCEDURE log_deploy_info(p_name VARCHAR2, p_svn_id VARCHAR2) IS
  BEGIN
    lv_proc_name := 'log_deploy_info';
    audit_pkg.log_pkg_init(p_name, p_svn_id);
  EXCEPTION
    WHEN OTHERS THEN
      dbadmin.audit_pkg.log_error(lc_svn_id, lv_proc_name, lv_comment, '', $$PLSQL_UNIT, $$PLSQL_LINE, SQLCODE, SQLERRM);
      IF lv_debug_lvl > 0 THEN
        RAISE;
      END IF;
  END log_deploy_info;

  PROCEDURE pop_cust_schema_tab IS
    n BINARY_INTEGER := 0;
  BEGIN
    lv_proc_name := 'pop_cust_schema_tab';
    lv_comment   := 'if the PL/SQL table has no records, initialize it';
    IF cust_schema_tab.count = 0 THEN
      FOR cust_schema_rec IN (SELECT owner
                                FROM all_objects
                               WHERE object_type = 'TABLE' AND object_name = cust_sch_indicator_tab
                               ORDER BY 1)
      LOOP
        n := n + 1;
        cust_schema_tab(n) := cust_schema_rec.owner;
      END LOOP;
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      dbadmin.audit_pkg.log_error(lc_svn_id, lv_proc_name, lv_comment, '', $$PLSQL_UNIT, $$PLSQL_LINE, SQLCODE, SQLERRM);
      IF lv_debug_lvl > 0 THEN
        RAISE;
      END IF;
  END pop_cust_schema_tab;

  PROCEDURE list_cust_schemas IS
  BEGIN
    lv_proc_name := 'list_cust_schemas';
    lv_comment   := 'if the PL/SQL table has no records, initialize it';
    pop_cust_schema_tab;
    IF cust_schema_tab.count = 0 THEN
      dbms_output.put_line('No customer schemas found !');
    ELSE
      lv_comment := 'loop over PL/SQL table printing records';
      FOR i IN cust_schema_tab.first .. cust_schema_tab.last
      LOOP
        dbms_output.put_line(cust_schema_tab(i));
      END LOOP;
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      dbadmin.audit_pkg.log_error(lc_svn_id, lv_proc_name, lv_comment, '', $$PLSQL_UNIT, $$PLSQL_LINE, SQLCODE, SQLERRM);
      IF lv_debug_lvl > 0 THEN
        RAISE;
      END IF;
  END list_cust_schemas;

  /*  FUNCTION is_cust_facing_db RETURN BOOLEAN IS
    BEGIN
      lv_proc_name := 'is_cust_facing_db';
      RETURN TRUE;
    EXCEPTION
      WHEN OTHERS THEN
        dbadmin.audit_pkg.log_error(lc_svn_id, lv_proc_name, lv_comment, '', $$PLSQL_UNIT, $$PLSQL_LINE, SQLCODE, SQLERRM);
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
        dbadmin.audit_pkg.log_error(lc_svn_id, lv_proc_name, lv_comment, '', $$PLSQL_UNIT, $$PLSQL_LINE, SQLCODE, SQLERRM);
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
        dbadmin.audit_pkg.log_error(lc_svn_id, lv_proc_name, lv_comment, '', $$PLSQL_UNIT, $$PLSQL_LINE, SQLCODE, SQLERRM);
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
        dbadmin.audit_pkg.log_error(lc_svn_id, lv_proc_name, lv_comment, '', $$PLSQL_UNIT, $$PLSQL_LINE, SQLCODE, SQLERRM);
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
            dbadmin.audit_pkg.log_error(lc_svn_id, lv_proc_name, lv_comment, '', $$PLSQL_UNIT, $$PLSQL_LINE, SQLCODE, SQLERRM);
        END;
      END LOOP;
    EXCEPTION
      WHEN OTHERS THEN
        dbadmin.audit_pkg.log_error(lc_svn_id, lv_proc_name, lv_comment, '', $$PLSQL_UNIT, $$PLSQL_LINE, SQLCODE, SQLERRM);
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
        dbadmin.audit_pkg.log_error(lc_svn_id, lv_proc_name, lv_comment, p_username, $$PLSQL_UNIT, $$PLSQL_LINE, SQLCODE, SQLERRM);
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
        dbadmin.audit_pkg.log_error(lc_svn_id, lv_proc_name, lv_comment, '', $$PLSQL_UNIT, $$PLSQL_LINE, SQLCODE, SQLERRM);
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
        dbadmin.audit_pkg.log_error(lc_svn_id, lv_proc_name, lv_comment, p_obj_owner || '.' ||
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
        dbadmin.audit_pkg.log_error(lc_svn_id, lv_proc_name, lv_comment, p_obj_type || ' ' ||
                                     p_obj_owner || '.' ||
                                     p_obj_name, $$PLSQL_UNIT, $$PLSQL_LINE, SQLCODE, SQLERRM);
    END synonyms_grants;
  */
  -- Example for p_update_sql: 'UPDATE /*+ ROWID (dda) */ order_items_ SET unit_amount_new = unit_amount WHERE rowid BETWEEN :start_id AND :end_id and unit_amount_new IS NULL';
  PROCEDURE update_rows(p_table_owner VARCHAR,
                        p_table_name  VARCHAR,
                        p_update_sql  VARCHAR,
                        p_chunk_size  PLS_INTEGER DEFAULT 5000) IS
    l_chunk_id    NUMBER;
    l_start_rowid ROWID;
    l_end_rowid   ROWID;
    l_any_rows    BOOLEAN;
    l_row_count   NUMBER;
  BEGIN
    lv_proc_name := 'update_rows';
    lv_comment   := 'Report runtime parameters';
    dbms_application_info.set_module(lv_proc_name, p_table_name);
    dbms_application_info.set_client_info('Starting up');
    lv_comment := 'Check for an existing task';
    SELECT COUNT(*)
      INTO l_row_count
      FROM sys.dba_parallel_execute_tasks
     WHERE task_name = p_table_name;
    IF (l_row_count > 0) THEN
      lv_comment := 'Drop the existing task';
      BEGIN
        dbms_parallel_execute.drop_task(p_table_name);
      EXCEPTION
        WHEN OTHERS THEN
          NULL;
      END;
    END IF;
    -- Create the Objects, task, and chunk by ROWID
    dbms_parallel_execute.create_task(p_table_name);
    dbms_parallel_execute.create_chunks_by_rowid(p_table_name, p_table_owner, p_table_name, TRUE, p_chunk_size);
    -- Process each chunk and commit.
    LOOP
      -- Get a chunk to process; if there is nothing to process, then exit the loop;
      dbms_parallel_execute.get_rowid_chunk(p_table_name, l_chunk_id, l_start_rowid, l_end_rowid, l_any_rows);
      IF (l_any_rows = FALSE) THEN
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
        EXECUTE IMMEDIATE p_update_sql
          USING l_start_rowid, l_end_rowid;
        dbms_parallel_execute.set_chunk_status(p_table_name, l_chunk_id, dbms_parallel_execute.processed);
        COMMIT;
      EXCEPTION
        WHEN OTHERS THEN
          dbms_parallel_execute.set_chunk_status(p_table_name, l_chunk_id, dbms_parallel_execute.processed_with_error, SQLCODE, SQLERRM);
      END;
    END LOOP;
  EXCEPTION
    WHEN OTHERS THEN
      dbadmin.audit_pkg.log_error(lc_svn_id, lv_proc_name, lv_comment, '', $$PLSQL_UNIT, $$PLSQL_LINE, SQLCODE, SQLERRM);
      IF lv_debug_lvl > 0 THEN
        RAISE;
      END IF;
  END update_rows;

  PROCEDURE deploy_new_schema(p_ticket VARCHAR, p_schema VARCHAR, p_comment VARCHAR DEFAULT NULL) IS
    v_exists PLS_INTEGER;
  BEGIN
    lv_proc_name := 'deploy_new_schema';
    lv_comment   := 'Checking if it already exists';
    SELECT COUNT(*) INTO v_exists FROM all_users WHERE username = upper(p_schema);
    IF (v_exists = 0) THEN
      lv_comment := 'Creating';
      EXECUTE IMMEDIATE 'CREATE USER ' || p_schema ||
                        ' IDENTIFIED BY "D(FB2346----32DF" DEFAULT TABLESPACE DATA1 QUOTA UNLIMITED ON DATA1 ENABLE EDITIONS ACCOUNT LOCK';
      lv_comment := 'Logging change';
      dbadmin.audit_pkg.log_ddl_change(NULL, p_schema, 'SCHEMA', NULL, p_ticket, NULL, p_comment, lc_svn_id);
      BEGIN
        EXECUTE IMMEDIATE 'GRANT RESOURCE TO ' || p_schema;
      EXCEPTION
        WHEN OTHERS THEN
          dbadmin.audit_pkg.log_error(lc_svn_id, lv_proc_name, lv_comment, p_ticket || ' ' ||
                                       p_schema, $$PLSQL_UNIT, $$PLSQL_LINE, SQLCODE, SQLERRM);
      END;
      BEGIN
        EXECUTE IMMEDIATE 'REVOKE CONNECT FROM ' || p_schema;
      EXCEPTION
        WHEN OTHERS THEN
          dbadmin.audit_pkg.log_error(lc_svn_id, lv_proc_name, lv_comment, p_ticket, $$PLSQL_UNIT, $$PLSQL_LINE, SQLCODE, SQLERRM);
      END;
      IF lv_debug_lvl > 5 THEN
        dbms_output.put_line('INFO: Schema ' || p_schema || ' created for ' || p_ticket);
      END IF;
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      dbadmin.audit_pkg.log_error(lc_svn_id, lv_proc_name, lv_comment, p_ticket, $$PLSQL_UNIT, $$PLSQL_LINE, SQLCODE, SQLERRM);
      IF lv_debug_lvl > 0 THEN
        RAISE;
      END IF;
  END deploy_new_schema;

  PROCEDURE deploy_new_table(p_ticket          VARCHAR,
                             p_table_owner     VARCHAR,
                             p_table_name      VARCHAR,
                             p_sql             VARCHAR,
                             p_partitioned_sql VARCHAR DEFAULT NULL,
                             p_comment         VARCHAR DEFAULT NULL) IS
    v_exists PLS_INTEGER;
  BEGIN
    lv_proc_name := 'deploy_new_table';
    lv_comment   := 'Checking if it already exists';
    SELECT COUNT(*)
      INTO v_exists
      FROM all_tables
     WHERE owner = upper(p_table_owner) AND table_name = upper(p_table_name);
    IF (v_exists = 0) THEN
      lv_comment := 'Creating table';
      IF (p_partitioned_sql IS NOT NULL)
         AND is_partitioned_db THEN
        EXECUTE IMMEDIATE p_partitioned_sql;
        lv_comment := 'Logging create partitioned table';
        dbadmin.audit_pkg.log_ddl_change(p_table_owner, p_table_name, 'TABLE', p_table_owner, p_ticket, p_partitioned_sql, p_comment, lc_svn_id);
      ELSE
        EXECUTE IMMEDIATE p_sql;
        lv_comment := 'Logging create table';
        dbadmin.audit_pkg.log_ddl_change(p_table_owner, p_table_name, 'TABLE', p_table_owner, p_ticket, p_sql, p_comment, lc_svn_id);
      END IF;
      IF (p_comment IS NOT NULL) THEN
        lv_comment := 'Adding comment:' || p_comment;
        EXECUTE IMMEDIATE 'comment on table ' || p_table_owner || '.' || p_table_name || ' is ''' ||
                          p_comment || '''';
      END IF;
      IF lv_debug_lvl > 5 THEN
        dbms_output.put_line('INFO: Table ' || p_table_owner || '.' || p_table_name ||
                             ' created for ' || p_ticket);
      END IF;
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      dbadmin.audit_pkg.log_error(lc_svn_id, lv_proc_name, lv_comment, p_ticket || ' ' ||
                                   p_table_owner || ' ' ||
                                   p_table_name, $$PLSQL_UNIT, $$PLSQL_LINE, SQLCODE, SQLERRM);
      IF lv_debug_lvl > 0 THEN
        RAISE;
      END IF;
  END deploy_new_table;

  PROCEDURE deploy_new_column(p_ticket      VARCHAR,
                              p_table_owner VARCHAR,
                              p_table_name  VARCHAR,
                              p_col_name    VARCHAR,
                              p_sql         VARCHAR,
                              p_comment     VARCHAR DEFAULT NULL) IS
    v_exists PLS_INTEGER;
  BEGIN
    lv_proc_name := 'deploy_new_column';
    lv_comment   := 'Checking if it already exists';
    SELECT COUNT(*)
      INTO v_exists
      FROM all_tab_cols
     WHERE owner = upper(p_table_owner) AND table_name = upper(p_table_name) AND
           column_name = upper(p_col_name);
    IF (v_exists = 0) THEN
      lv_comment := 'Creating';
      EXECUTE IMMEDIATE p_sql;
      lv_comment := 'Logging change';
      dbadmin.audit_pkg.log_ddl_change(p_table_owner, p_col_name, 'COLUMN', p_table_name, p_ticket, p_sql, p_comment, lc_svn_id);
      IF (p_comment IS NOT NULL) THEN
        lv_comment := 'Adding comment';
        EXECUTE IMMEDIATE 'comment on column ' || p_table_owner || '.' || p_table_name || '.' ||
                          p_col_name || ' is ''' || p_comment || '''';
      END IF;
      IF lv_debug_lvl > 5 THEN
        dbms_output.put_line('INFO: Column ' || p_col_name || ' added to table ' || p_table_owner || '.' ||
                             p_table_name || ' for ' || p_ticket);
      END IF;
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      dbadmin.audit_pkg.log_error(lc_svn_id, lv_proc_name, lv_comment, p_ticket || ' ' ||
                                   p_table_owner || ' ' ||
                                   p_table_name || ' ' ||
                                   p_col_name, $$PLSQL_UNIT, $$PLSQL_LINE, SQLCODE, SQLERRM);
      IF lv_debug_lvl > 0 THEN
        RAISE;
      END IF;
  END deploy_new_column;

  PROCEDURE deploy_new_index(p_ticket          VARCHAR,
                             p_table_owner     VARCHAR,
                             p_table_name      VARCHAR,
                             p_index_name      VARCHAR,
                             p_sql             VARCHAR,
                             p_partitioned_sql VARCHAR DEFAULT NULL,
                             p_comment         VARCHAR DEFAULT NULL) IS
    v_exists PLS_INTEGER;
  BEGIN
    lv_proc_name := 'deploy_new_index';
    lv_comment   := 'Checking if it already exists';
    SELECT COUNT(*)
      INTO v_exists
      FROM all_indexes
     WHERE owner = upper(p_table_owner) AND table_name = upper(p_table_name) AND
           index_name = upper(p_index_name);
    IF (v_exists = 0) THEN
      lv_comment := 'Creating';
      IF (p_partitioned_sql IS NOT NULL)
         AND is_partitioned_db THEN
        EXECUTE IMMEDIATE p_partitioned_sql;
        lv_comment := 'Logging create partitioned index';
        dbadmin.audit_pkg.log_ddl_change(p_table_owner, p_index_name, 'INDEX', p_table_name, p_ticket, p_partitioned_sql, p_comment, lc_svn_id);
      ELSE
        EXECUTE IMMEDIATE p_sql;
        lv_comment := 'Logging create index';
        dbadmin.audit_pkg.log_ddl_change(p_table_owner, p_index_name, 'INDEX', p_table_name, p_ticket, p_sql, p_comment, lc_svn_id);
      END IF;
      IF lv_debug_lvl > 5 THEN
        dbms_output.put_line('INFO: Index ' || p_index_name || ' added to table ' || p_table_owner || '.' ||
                             p_table_name || ' for ' || p_ticket);
      END IF;
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      dbadmin.audit_pkg.log_error(lc_svn_id, lv_proc_name, lv_comment, p_ticket || ' ' ||
                                   p_table_owner || ' ' ||
                                   p_table_name || ' ' ||
                                   p_index_name, $$PLSQL_UNIT, $$PLSQL_LINE, SQLCODE, SQLERRM);
      IF lv_debug_lvl > 0 THEN
        RAISE;
      END IF;
  END deploy_new_index;

  PROCEDURE deploy_new_sequence(p_ticket   VARCHAR,
                                p_owner    VARCHAR,
                                p_seq_name VARCHAR,
                                p_sql      VARCHAR DEFAULT NULL,
                                p_comment  VARCHAR DEFAULT NULL) IS
    v_exists PLS_INTEGER;
    v_sql    VARCHAR2(200);
  BEGIN
    lv_proc_name := 'deploy_new_sequence';
    lv_comment   := 'Checking if it already exists';
    SELECT COUNT(*)
      INTO v_exists
      FROM all_sequences
     WHERE sequence_owner = upper(p_owner) AND sequence_name = upper(p_seq_name);
    IF (v_exists = 0) THEN
      lv_comment := 'Creating';
      v_sql      := p_sql;
      IF p_sql IS NULL THEN
        v_sql := 'CREATE SEQUENCE ' || p_owner || '.' || p_seq_name || ' NOCACHE';
      END IF;
      EXECUTE IMMEDIATE v_sql;
      lv_comment := 'Logging change';
      dbadmin.audit_pkg.log_ddl_change(p_owner, p_seq_name, 'SEQUENCE', NULL, p_ticket, v_sql, p_comment, lc_svn_id);
      IF lv_debug_lvl > 5 THEN
        dbms_output.put_line('INFO: Sequence ' || p_owner || '.' || p_seq_name || ' created for ' ||
                             p_ticket);
      END IF;
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      dbadmin.audit_pkg.log_error(lc_svn_id, lv_proc_name, lv_comment, p_ticket || ' ' || p_owner || ' ' ||
                                   p_seq_name, $$PLSQL_UNIT, $$PLSQL_LINE, SQLCODE, SQLERRM);
      IF lv_debug_lvl > 0 THEN
        RAISE;
      END IF;
  END deploy_new_sequence;

  -- This creates a sequence in the "cust_seq_schema" schema and then makes select grants to all customer schemas
  -- Passing the create DDL is optional, but if you do, be sure to specify "cust_seq_schema" as the schema
  PROCEDURE deploy_new_sequence_cust(p_ticket   VARCHAR,
                                     p_seq_name VARCHAR,
                                     p_sql      VARCHAR DEFAULT NULL,
                                     p_comment  VARCHAR DEFAULT NULL) IS
  BEGIN
    lv_proc_name := 'deploy_new_sequence_cust';
    lv_comment   := 'Create sequence in ' || cust_seq_schema || ' schema';
    deploy_new_sequence(p_ticket, cust_seq_schema, p_seq_name, p_sql, p_comment);
    lv_comment := 'Make grants to all cust schemas';
    pop_cust_schema_tab;
    IF cust_schema_tab.count > 0 THEN
      lv_comment := 'Loop over PL/SQL table - granting access';
      FOR i IN cust_schema_tab.first .. cust_schema_tab.last
      LOOP
        lv_comment := 'GRANT SELECT ON ' || cust_seq_schema || '.' || p_seq_name || ' TO ' ||
                      cust_schema_tab(i);
        EXECUTE IMMEDIATE 'GRANT SELECT ON ' || cust_seq_schema || '.' || p_seq_name || ' TO ' ||
                          cust_schema_tab(i);
      END LOOP;
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      dbadmin.audit_pkg.log_error(lc_svn_id, lv_proc_name, lv_comment, p_ticket || ' ' ||
                                   cust_seq_schema || ' ' ||
                                   p_seq_name, $$PLSQL_UNIT, $$PLSQL_LINE, SQLCODE, SQLERRM);
      IF lv_debug_lvl > 0 THEN
        RAISE;
      END IF;
  END deploy_new_sequence_cust;

  PROCEDURE deploy_new_constraint(p_ticket          VARCHAR,
                                  p_table_owner     VARCHAR,
                                  p_table_name      VARCHAR,
                                  p_constraint_name VARCHAR,
                                  p_sql             VARCHAR,
                                  p_comment         VARCHAR DEFAULT NULL) IS
    v_exists PLS_INTEGER;
  BEGIN
    lv_proc_name := 'deploy_new_constraint';
    lv_comment   := 'Checking if it already exists';
    SELECT COUNT(*)
      INTO v_exists
      FROM all_constraints
     WHERE owner = upper(p_table_owner) AND table_name = upper(p_table_name) AND
           constraint_name = upper(p_constraint_name);
    IF (v_exists = 0) THEN
      lv_comment := 'Creating';
      EXECUTE IMMEDIATE p_sql;
      lv_comment := 'Logging change';
      dbadmin.audit_pkg.log_ddl_change(p_table_owner, p_constraint_name, 'CONSTRAINT', p_table_name, p_ticket, p_sql, p_comment, lc_svn_id);
      IF lv_debug_lvl > 5 THEN
        dbms_output.put_line('INFO: Constraint ' || p_constraint_name || ' added to table ' ||
                             p_table_owner || '.' || p_table_name || ' for ' || p_ticket);
      END IF;
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      dbadmin.audit_pkg.log_error(lc_svn_id, lv_proc_name, lv_comment, p_ticket || ' ' ||
                                   p_table_owner || ' ' ||
                                   p_table_name || ' ' ||
                                   p_constraint_name, $$PLSQL_UNIT, $$PLSQL_LINE, SQLCODE, SQLERRM);
      IF lv_debug_lvl > 0 THEN
        RAISE;
      END IF;
  END deploy_new_constraint;

  PROCEDURE deploy_new_job(p_ticket   VARCHAR,
                           p_owner    VARCHAR,
                           p_job_name VARCHAR,
                           p_sql      VARCHAR,
                           p_comment  VARCHAR DEFAULT NULL) IS
    v_exists PLS_INTEGER;
  BEGIN
    lv_proc_name := 'deploy_new_job';
    lv_comment   := 'Checking if the job already exists';
    SELECT COUNT(*)
      INTO v_exists
      FROM sys.dba_scheduler_jobs
     WHERE owner = upper(p_owner) AND job_name = upper(p_job_name);
    IF (v_exists = 0) THEN
      lv_comment := 'Creating job';
      EXECUTE IMMEDIATE p_sql;
      lv_comment := 'Logging change';
      dbadmin.audit_pkg.log_ddl_change(p_owner, p_job_name, 'JOB', NULL, p_ticket, p_sql, p_comment, lc_svn_id);
      IF lv_debug_lvl > 5 THEN
        dbms_output.put_line('INFO: Oracle Job ' || p_owner || '.' || p_job_name ||
                             ' created for ' || p_ticket);
      END IF;
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      dbadmin.audit_pkg.log_error(lc_svn_id, lv_proc_name, lv_comment, p_ticket || ' ' || p_owner || ' ' ||
                                   p_job_name, $$PLSQL_UNIT, $$PLSQL_LINE, SQLCODE, SQLERRM);
      IF lv_debug_lvl > 0 THEN
        RAISE;
      END IF;
  END deploy_new_job;

  PROCEDURE deploy_alter_column(p_ticket      VARCHAR,
                                p_table_owner VARCHAR,
                                p_table_name  VARCHAR,
                                p_col_name    VARCHAR,
                                p_sql         VARCHAR,
                                p_comment     VARCHAR DEFAULT NULL) IS
    v_exists PLS_INTEGER;
  BEGIN
    lv_proc_name := 'deploy_alter_column';
    lv_comment   := 'Checking if it already exists';
    SELECT COUNT(*)
      INTO v_exists
      FROM all_tab_cols
     WHERE owner = upper(p_table_owner) AND table_name = upper(p_table_name) AND
           column_name = upper(p_col_name);
    IF (v_exists = 1) THEN
      lv_comment := 'Altering';
      EXECUTE IMMEDIATE p_sql;
      lv_comment := 'Logging change';
      dbadmin.audit_pkg.log_ddl_change(p_table_owner, p_col_name, 'COLUMN', p_table_name, p_ticket, p_sql, p_comment, lc_svn_id);
      IF (p_comment IS NOT NULL) THEN
        lv_comment := 'Adding comment';
        EXECUTE IMMEDIATE 'comment on column ' || p_table_owner || '.' || p_table_name || '.' ||
                          p_col_name || ' is ''' || p_comment || '''';
      END IF;
      IF lv_debug_lvl > 5 THEN
        dbms_output.put_line('INFO: Column ' || p_col_name || ' on table ' || p_table_owner || '.' ||
                             p_table_name || ' altered for ' || p_ticket);
      END IF;
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      dbadmin.audit_pkg.log_error(lc_svn_id, lv_proc_name, lv_comment, p_ticket || ' ' ||
                                   p_table_owner || ' ' ||
                                   p_table_name || ' ' ||
                                   p_col_name, $$PLSQL_UNIT, $$PLSQL_LINE, SQLCODE, SQLERRM);
      IF lv_debug_lvl > 0 THEN
        RAISE;
      END IF;
  END deploy_alter_column;

  PROCEDURE deploy_ddl(p_ticket VARCHAR, p_sql VARCHAR, p_comment VARCHAR DEFAULT NULL) IS
  BEGIN
    lv_proc_name := 'deploy_ddl';
    EXECUTE IMMEDIATE p_sql;
    dbadmin.audit_pkg.log_ddl_change(NULL, NULL, NULL, NULL, p_ticket, p_sql, p_comment, lc_svn_id);
    IF lv_debug_lvl > 5 THEN
      dbms_output.put_line('INFO: Generic DDL ' || p_sql || ' performed for ' || p_ticket);
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      dbadmin.audit_pkg.log_error(lc_svn_id, lv_proc_name, lv_comment, p_ticket, $$PLSQL_UNIT, $$PLSQL_LINE, SQLCODE, SQLERRM);
      IF lv_debug_lvl > 0 THEN
        RAISE;
      END IF;
  END deploy_ddl;

  PROCEDURE drop_object(p_ticket  VARCHAR,
                        p_type    VARCHAR,
                        p_owner   VARCHAR,
                        p_name    VARCHAR,
                        p_sql     VARCHAR DEFAULT NULL,
                        p_comment VARCHAR DEFAULT NULL) IS
    l_cnt    PLS_INTEGER;
    l_parent VARCHAR2(100);
  BEGIN
    lv_proc_name := 'drop_object';
    CASE p_type
      WHEN 'JOB' THEN
        lv_comment := 'Checking for existance of job';
        SELECT COUNT(*)
          INTO l_cnt
          FROM sys.dba_scheduler_jobs
         WHERE owner = upper(p_owner) AND job_name = upper(p_name);
        IF (l_cnt > 0) THEN
          lv_comment := 'Dropping ' || p_name || ' job';
          sys.dbms_scheduler.drop_job(p_owner || '.' || p_name);
          lv_comment := 'Logging change';
          dbadmin.audit_pkg.log_ddl_change(p_owner, p_name, p_type, NULL, p_ticket, NULL, 'Dropped: ' ||
                                            p_comment, lc_svn_id);
          IF lv_debug_lvl > 5 THEN
            dbms_output.put_line('INFO: ' || p_type || ' ' || p_owner || '.' || p_name ||
                                 ' dropped for ' || p_ticket);
          END IF;
        END IF;
      WHEN 'CONSTRAINT' THEN
        lv_comment := 'Checking for existance of constraint';
        SELECT COUNT(*)
          INTO l_cnt
          FROM all_constraints
         WHERE owner = upper(p_owner) AND constraint_name = upper(p_name);
        IF (l_cnt > 0) THEN
          SELECT table_name
            INTO l_parent
            FROM all_constraints
           WHERE owner = upper(p_owner) AND constraint_name = upper(p_name);
          lv_comment := 'Dropping ' || p_name || ' constraint';
          EXECUTE IMMEDIATE 'alter table ' || p_owner || '.' || l_parent || ' drop constraint ' ||
                            p_name;
          lv_comment := 'Logging change';
          dbadmin.audit_pkg.log_ddl_change(p_owner, p_name, p_type, NULL, p_ticket, NULL, 'Dropped: ' ||
                                            p_comment, lc_svn_id);
          IF lv_debug_lvl > 5 THEN
            dbms_output.put_line('INFO: ' || p_type || ' ' || p_owner || '.' || p_name ||
                                 ' dropped for ' || p_ticket);
          END IF;
        END IF;
      WHEN 'COLUMN' THEN
        lv_comment := 'Checking for existance of column';
        SELECT COUNT(*)
          INTO l_cnt
          FROM all_tab_cols
         WHERE owner = upper(p_owner) AND column_name = upper(p_name);
        IF (l_cnt > 0) THEN
          SELECT table_name
            INTO l_parent
            FROM all_tab_cols
           WHERE owner = upper(p_owner) AND column_name = upper(p_name);
          lv_comment := 'Dropping ' || p_name || ' constraint';
          EXECUTE IMMEDIATE 'alter table ' || p_owner || '.' || l_parent || ' drop column ' ||
                            p_name;
          lv_comment := 'Logging change';
          dbadmin.audit_pkg.log_ddl_change(p_owner, p_name, p_type, NULL, p_ticket, NULL, 'Dropped: ' ||
                                            p_comment, lc_svn_id);
          IF lv_debug_lvl > 5 THEN
            dbms_output.put_line('INFO: ' || p_type || ' ' || p_owner || '.' || p_name ||
                                 ' dropped for ' || p_ticket);
          END IF;
        END IF;
      ELSE
        lv_comment := 'Checking for existance';
        SELECT COUNT(*)
          INTO l_cnt
          FROM all_objects
         WHERE object_type = upper(p_type) AND owner = upper(p_owner) AND
               object_name = upper(p_name);
        IF (l_cnt > 0) THEN
          lv_comment := 'Dropping';
          IF (p_sql IS NULL) THEN
            EXECUTE IMMEDIATE 'drop ' || p_type || ' ' || p_owner || '.' || p_name;
          ELSE
            EXECUTE IMMEDIATE p_sql;
            lv_comment := 'Logging change';
            dbadmin.audit_pkg.log_ddl_change(p_owner, p_name, p_type, NULL, p_ticket, p_sql, 'Dropped: ' ||
                                              p_comment, lc_svn_id);
          END IF;
          IF lv_debug_lvl > 5 THEN
            dbms_output.put_line('INFO: ' || p_type || ' ' || p_owner || '.' || p_name ||
                                 ' dropped for ' || p_ticket);
          END IF;
        END IF;
    END CASE;
  EXCEPTION
    WHEN OTHERS THEN
      dbadmin.audit_pkg.log_error(lc_svn_id, lv_proc_name, lv_comment, p_ticket || ' ' || p_type || ' ' ||
                                   p_owner || '.' || p_name, $$PLSQL_UNIT, $$PLSQL_LINE, SQLCODE, SQLERRM);
      IF lv_debug_lvl > 0 THEN
        RAISE;
      END IF;
  END drop_object;

  FUNCTION backup_table_name(p_ticket VARCHAR, p_table_owner VARCHAR, p_table_name VARCHAR)
    RETURN VARCHAR IS
    v_name VARCHAR2(200);
    v_size PLS_INTEGER;
  BEGIN
    lv_proc_name := 'backup_table_name';
    lv_comment   := 'Get length of the ticket string to append';
    v_size       := length(p_ticket);
    lv_comment   := 'construct the name, making sure the ticket will fit in 30 chars and sub invalid chars';
    v_name       := REPLACE(substr(p_table_owner || '_' || p_table_name, 1, 29 - v_size) || '_' ||
                            p_ticket, '-', '_');
    lv_comment   := 'return the first 30 chars';
    RETURN substr(v_name, 1, 30);
  EXCEPTION
    WHEN OTHERS THEN
      dbadmin.audit_pkg.log_error(lc_svn_id, lv_proc_name, lv_comment, p_ticket || ' ' ||
                                   p_table_owner || '.' ||
                                   p_table_name, $$PLSQL_UNIT, $$PLSQL_LINE, SQLCODE, SQLERRM);
      IF lv_debug_lvl > 0 THEN
        RAISE;
      END IF;
  END backup_table_name;

  PROCEDURE backup_table_name(p_ticket VARCHAR, p_table_owner VARCHAR, p_table_name VARCHAR) IS
    v_name VARCHAR2(200);
  BEGIN
    lv_proc_name := 'backup_table_name';
    lv_comment   := 'call backup_table_name function';
    v_name       := backup_table_name(p_ticket, p_table_owner, p_table_name);
    lv_comment   := 'print result';
    dbms_output.put_line(backup_schema || '.' || v_name);
  EXCEPTION
    WHEN OTHERS THEN
      dbadmin.audit_pkg.log_error(lc_svn_id, lv_proc_name, lv_comment, p_ticket || ' ' ||
                                   p_table_owner || '.' ||
                                   p_table_name, $$PLSQL_UNIT, $$PLSQL_LINE, SQLCODE, SQLERRM);
      IF lv_debug_lvl > 0 THEN
        RAISE;
      END IF;
  END backup_table_name;

  /* dbadmin.deploy_utils.backup_data
  This creates a backup copy of a table (or a subset of the table's rows)
  The resulting backup table name contains the ticket info and the originating schema (if needed)
  p_sql - optional select statement to only save some of the rows, default is "select *" from the table
    if using this on a table in the cust schemas, you must use 'MASTER_SCHEMA' as the table owner.
    This is replaced bythe correct schema name for each cust schema
  p_expire_date - specify a date the data can be removed, default is create time + 30 days
  p_comment - optional comment to describe how to use the data, or why it was saved
  
  Features:
  1. Details of this backup operation will be stored in the dbadmin.data_audit_log table.
  2. If p_table_owner is MASTER_SCHEMA, also perform a backup of all the cust schemas with this one call
  3. Create a function that accepts the same first 3 parameters and returns the name of the backup table
  4. Add expire date as comment on backup table
  */
  PROCEDURE backup_data(p_ticket      VARCHAR,
                        p_table_owner VARCHAR,
                        p_table_name  VARCHAR,
                        p_sql         VARCHAR DEFAULT NULL,
                        p_expire_date DATE DEFAULT NULL,
                        p_comment     VARCHAR DEFAULT NULL) IS
    v_sql            VARCHAR2(32000);
    v_bkp_table_name VARCHAR2(35);
    v_expire         VARCHAR2(35);
    v_comment        VARCHAR2(4000);
  
    PROCEDURE bkp_1_table(p_ticket      VARCHAR,
                          p_table_owner VARCHAR,
                          p_table_name  VARCHAR,
                          p_sql         VARCHAR DEFAULT NULL,
                          p_comment     VARCHAR) IS
      v_cnt            PLS_INTEGER;
      v_sql            VARCHAR2(32000);
      v_bkp_table_name VARCHAR2(35);
    BEGIN
      lv_comment := 'in bkp_1_table proc';
      IF p_sql IS NULL THEN
        v_sql := 'select * from ' || p_table_owner || '.' || p_table_name;
      ELSE
        v_sql := REPLACE(p_sql, 'MASTER_SCHEMA', p_table_owner);
      END IF;
      lv_comment := 'chk for existance of the source table';
      SELECT COUNT(*)
        INTO v_cnt
        FROM all_tables
       WHERE owner = p_table_owner AND table_name = p_table_name;
      IF v_cnt = 1 THEN
        lv_comment       := 'performing backup';
        v_bkp_table_name := backup_table_name(p_ticket, p_table_owner, p_table_name);
        lv_comment       := 'chk for existance of the backup table';
        SELECT COUNT(*)
          INTO v_cnt
          FROM all_tables
         WHERE owner = backup_schema AND table_name = v_bkp_table_name;
        IF v_cnt = 0 THEN
          lv_comment := 'bkp_1_table - create table ' || backup_schema || '.' || v_bkp_table_name ||
                        ' as ' || v_sql;
          EXECUTE IMMEDIATE 'create table ' || backup_schema || '.' || v_bkp_table_name || ' as ' ||
                            v_sql;
          lv_comment := 'bkp_1_table - comment on table ' || backup_schema || '.' ||
                        v_bkp_table_name || ' IS ''' || p_comment || '''';
          EXECUTE IMMEDIATE 'comment on table ' || backup_schema || '.' || v_bkp_table_name ||
                            ' IS ''' || p_comment || '''';
          lv_comment := 'logging change';
          INSERT INTO data_audit_log
            (log_timestamp,
             user_name,
             app_name,
             tab_owner,
             tab_name,
             action_type,
             dml_type,
             log_comment)
          VALUES
            (systimestamp,
             USER,
             'deploy_utils.backup_data',
             p_table_owner,
             p_table_name,
             'BACKUP',
             'CTAS',
             p_comment);
          lv_comment := 'Report change';
        END IF;
        IF lv_debug_lvl > 5 THEN
          dbms_output.put_line('INFO: Table ' || p_table_owner || '.' || p_table_name ||
                               ' backed up for ' || p_ticket);
        END IF;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        dbadmin.audit_pkg.log_error(lc_svn_id, lv_proc_name, lv_comment, p_ticket || ' ' ||
                                     p_table_owner || '.' ||
                                     p_table_name, $$PLSQL_UNIT, $$PLSQL_LINE, SQLCODE, SQLERRM);
    END bkp_1_table;
  BEGIN
    lv_proc_name := 'backup_data';
    lv_comment   := 'computing expiration date';
    IF p_expire_date IS NULL THEN
      v_expire := to_char(SYSDATE + 30, 'DD-MON-YYYY');
    ELSE
      v_expire := to_char(p_expire_date, 'DD-MON-YYYY');
    END IF;
    lv_comment := 'computing change comment';
    v_comment  := substr(p_ticket || ' Expires: ' || v_expire || ' ' || p_comment, 1, 4000);
    lv_comment := 'Checking if this goes to all cust schemas';
    IF p_table_owner = 'MASTER_SCHEMA' THEN
      lv_comment := 'if the PL/SQL table has no records, initialize it';
      pop_cust_schema_tab;
      lv_comment := 'loop over all the cust schemas';
      FOR i IN cust_schema_tab.first .. cust_schema_tab.last
      LOOP
        bkp_1_table(p_ticket, cust_schema_tab(i), p_table_name, p_sql, v_comment);
      END LOOP;
    ELSE
      bkp_1_table(p_ticket, p_table_owner, p_table_name, p_sql, v_comment);
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      dbadmin.audit_pkg.log_error(lc_svn_id, lv_proc_name, lv_comment, p_ticket || ' ' ||
                                   p_table_owner || '.' ||
                                   p_table_name, $$PLSQL_UNIT, $$PLSQL_LINE, SQLCODE, SQLERRM);
      IF lv_debug_lvl > 0 THEN
        RAISE;
      END IF;
  END backup_data;

  -- purge_backup_data - purges the backup data if it is past it's expire date
  -- the force option ignores the expiration date and always drops the data
  PROCEDURE purge_backup_data(p_ticket      VARCHAR,
                              p_table_owner VARCHAR,
                              p_table_name  VARCHAR,
                              force         BOOLEAN DEFAULT FALSE) IS
    v_bkp_table_name VARCHAR2(35);
  
    PROCEDURE purge_1_table(p_ticket      VARCHAR,
                            p_table_owner VARCHAR,
                            p_table_name  VARCHAR,
                            force         BOOLEAN DEFAULT FALSE) IS
      v_cnt            PLS_INTEGER;
      v_age            PLS_INTEGER;
      v_bkp_table_name VARCHAR2(35);
      v_expired        BOOLEAN := FALSE;
    BEGIN
      lv_comment := 'in purge_1_table proc';
      lv_comment := 'chk for existance of the backup table';
      SELECT COUNT(*)
        INTO v_cnt
        FROM all_tables
       WHERE owner = backup_schema AND table_name = v_bkp_table_name;
      IF v_cnt = 1 THEN
        lv_comment := 'chk expiration status of the backup table';
        -- check here
        SELECT round(SYSDATE - nvl(MAX(created), SYSDATE))
          INTO v_age
          FROM all_objects
         WHERE owner = backup_schema AND object_name = v_bkp_table_name AND object_type = 'TABLE';
        IF v_age > 30 THEN
          v_expired := TRUE;
        END IF;
        IF v_expired
           OR force THEN
          EXECUTE IMMEDIATE 'drop table ' || backup_schema || '.' || v_bkp_table_name;
          lv_comment := 'logging change';
          INSERT INTO data_audit_log
            (log_timestamp,
             user_name,
             app_name,
             tab_owner,
             tab_name,
             action_type,
             dml_type,
             log_comment)
          VALUES
            (systimestamp,
             USER,
             'deploy_utils.purge_backup_data',
             p_table_owner,
             p_table_name,
             'PURGE',
             'DROP',
             '');
        END IF;
        IF lv_debug_lvl > 5 THEN
          dbms_output.put_line('INFO: Backup data from ' || p_table_owner || '.' || p_table_name ||
                               ' purged for ' || p_ticket);
        END IF;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        dbadmin.audit_pkg.log_error(lc_svn_id, lv_proc_name, lv_comment, p_ticket || ' ' ||
                                     p_table_owner || '.' ||
                                     p_table_name, $$PLSQL_UNIT, $$PLSQL_LINE, SQLCODE, SQLERRM);
    END purge_1_table;
  BEGIN
    lv_proc_name := 'purge_backup_data';
    lv_comment   := 'Checking if this goes to all cust schemas';
    IF p_table_owner = 'MASTER_SCHEMA' THEN
      lv_comment := 'if the PL/SQL table has no records, initialize it';
      pop_cust_schema_tab;
      lv_comment := 'loop over all the cust schemas';
      FOR i IN cust_schema_tab.first .. cust_schema_tab.last
      LOOP
        purge_1_table(p_ticket, cust_schema_tab(i), p_table_name, force);
      END LOOP;
    ELSE
      purge_1_table(p_ticket, p_table_owner, p_table_name, force);
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      dbadmin.audit_pkg.log_error(lc_svn_id, lv_proc_name, lv_comment, p_ticket || ' ' ||
                                   p_table_owner || '.' ||
                                   p_table_name, $$PLSQL_UNIT, $$PLSQL_LINE, SQLCODE, SQLERRM);
      IF lv_debug_lvl > 0 THEN
        RAISE;
      END IF;
  END purge_backup_data;

BEGIN
  audit_pkg.log_pkg_init($$PLSQL_UNIT, lc_svn_id);
END deploy_utils;
/
SHOW ERRORS

