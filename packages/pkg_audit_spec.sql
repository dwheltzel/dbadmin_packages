CREATE OR REPLACE PACKAGE PKG_AUDIT IS
  -- Author: dheltzel
  PROCEDURE test_harness_log_error;

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
                               p_sqlerrm     err_log.sqlerrm%TYPE);

  PROCEDURE log_error(p_svn_id     VARCHAR2,
                      p_proc_name  err_log.proc_name%TYPE,
                      p_error_loc  err_log.error_loc%TYPE,
                      p_error_data err_log.error_data%TYPE,
                      p_plsql_unit err_log.plsql_unit%TYPE,
                      p_plsql_line err_log.plsql_line%TYPE,
                      p_sqlcode    err_log.sqlcode%TYPE,
                      p_sqlerrm    err_log.sqlerrm%TYPE);

  PROCEDURE log_action(p_app_name    VARCHAR2,
                       p_action_type VARCHAR2,
                       p_log_comment VARCHAR2);

  PROCEDURE log_data_change(p_app_name      VARCHAR2,
                            p_owner         VARCHAR2,
                            p_table_name    VARCHAR2,
                            p_action_type   VARCHAR2,
                            p_dml_type      VARCHAR2,
                            p_recs_affected INTEGER,
                            p_log_comment   VARCHAR2);

  PROCEDURE log_ddl_change(p_object_owner VARCHAR2,
                           p_object_name  VARCHAR2,
                           p_object_type  VARCHAR2,
                           p_parent_name  VARCHAR2,
                           p_ticket       VARCHAR2,
                           p_sql_executed VARCHAR2,
                           p_message      VARCHAR2,
                           p_svn_id       VARCHAR2);

  PROCEDURE log_pkg_init(p_package VARCHAR2, p_svn_id VARCHAR2);

END PKG_AUDIT;
/

