SET DEFINE OFF

CREATE OR REPLACE PACKAGE BODY dbadmin.registry IS

  -- File $Id: registry_body.sql 1419 2013-11-20 20:49:39Z dheltzel $
  -- Modified $Author: dheltzel $
  -- Date $Date: 2013-11-20 15:49:39 -0500 (Wed, 20 Nov 2013) $
  -- Revision $Revision: 1419 $
  lc_svn_id VARCHAR2(200) := '$Id: registry_body.sql 1419 2013-11-20 20:49:39Z dheltzel $';

  lv_proc_name err_log.proc_name%TYPE;

  lv_comment err_log.source_file%TYPE := 'Starting';

  pkg_namespace registrytable.namespace%TYPE := 'MAAS360';

  pkg_envir registrytable.envir%TYPE := 'A';

  FUNCTION get_namespace RETURN VARCHAR2 IS
  BEGIN
    lv_proc_name := 'get_namespace';
    RETURN(pkg_namespace);
  EXCEPTION
    WHEN OTHERS THEN
      dbadmin.audit_pkg.log_error(lc_svn_id,
                                lv_proc_name,
                                lv_comment,
                                pkg_namespace,
                                $$PLSQL_UNIT,
                                $$PLSQL_LINE,
                                SQLCODE,
                                SQLERRM);
  END get_namespace;

  PROCEDURE set_namespace(p_namespace VARCHAR2) IS
  BEGIN
    lv_proc_name  := 'set_namespace';
    pkg_namespace := p_namespace;
  EXCEPTION
    WHEN OTHERS THEN
      dbadmin.audit_pkg.log_error(lc_svn_id,
                                lv_proc_name,
                                lv_comment,
                                p_namespace,
                                $$PLSQL_UNIT,
                                $$PLSQL_LINE,
                                SQLCODE,
                                SQLERRM);
  END set_namespace;

  PROCEDURE clear_namespace IS
  BEGIN
    lv_proc_name  := 'clear_namespace';
    pkg_namespace := 'MAAS360';
  EXCEPTION
    WHEN OTHERS THEN
      dbadmin.audit_pkg.log_error(lc_svn_id,
                                lv_proc_name,
                                lv_comment,
                                pkg_namespace,
                                $$PLSQL_UNIT,
                                $$PLSQL_LINE,
                                SQLCODE,
                                SQLERRM);
  END clear_namespace;

  FUNCTION get_environment RETURN VARCHAR2 IS
  BEGIN
    lv_proc_name := 'get_environment';
    RETURN(pkg_envir);
  EXCEPTION
    WHEN OTHERS THEN
      dbadmin.audit_pkg.log_error(lc_svn_id,
                                lv_proc_name,
                                lv_comment,
                                pkg_envir,
                                $$PLSQL_UNIT,
                                $$PLSQL_LINE,
                                SQLCODE,
                                SQLERRM);
  END get_environment;

  PROCEDURE set_environment(p_envir VARCHAR2) IS
  BEGIN
    lv_proc_name := 'set_environment';
    pkg_envir    := p_envir;
  EXCEPTION
    WHEN OTHERS THEN
      dbadmin.audit_pkg.log_error(lc_svn_id,
                                lv_proc_name,
                                lv_comment,
                                pkg_envir,
                                $$PLSQL_UNIT,
                                $$PLSQL_LINE,
                                SQLCODE,
                                SQLERRM);
  END set_environment;

  PROCEDURE clear_environment IS
  BEGIN
    lv_proc_name := 'clear_environment';
    pkg_envir    := 'A';
  EXCEPTION
    WHEN OTHERS THEN
      dbadmin.audit_pkg.log_error(lc_svn_id,
                                lv_proc_name,
                                lv_comment,
                                pkg_envir,
                                $$PLSQL_UNIT,
                                $$PLSQL_LINE,
                                SQLCODE,
                                SQLERRM);
  END clear_environment;

  FUNCTION get_value(p_name      VARCHAR2,
                     p_namespace VARCHAR2 DEFAULT NULL,
                     p_envir     VARCHAR2 DEFAULT NULL,
                     p_default   VARCHAR2 DEFAULT NULL) RETURN VARCHAR2 IS
    RESULT      VARCHAR2(4000);
    l_namespace registrytable.namespace%TYPE := nvl(p_namespace,
                                                    pkg_namespace);
    l_envir     registrytable.envir%TYPE := nvl(p_envir, pkg_envir);
  BEGIN
    lv_proc_name := 'get_value';
    -- Select the value with an aggregate function so it returns NULL on no records found
    -- and allows an override to the passed in default if null or not found
    SELECT nvl(MAX(VALUE), p_default)
      INTO RESULT
      FROM registrytable
     WHERE namespace = l_namespace
       AND envir = l_envir
       AND NAME = p_name;
    RETURN(RESULT);
  EXCEPTION
    WHEN OTHERS THEN
      dbadmin.audit_pkg.log_error(lc_svn_id,
                                lv_proc_name,
                                lv_comment,
                                p_name || ' ' || p_namespace || ' ' ||
                                p_envir,
                                $$PLSQL_UNIT,
                                $$PLSQL_LINE,
                                SQLCODE,
                                SQLERRM);
  END get_value;

  FUNCTION insert_value(p_name      VARCHAR2,
                        p_value     VARCHAR2,
                        p_namespace VARCHAR2 DEFAULT NULL,
                        p_envir     VARCHAR2 DEFAULT NULL,
                        p_immutable VARCHAR2 DEFAULT 'N') RETURN BOOLEAN IS
    PRAGMA AUTONOMOUS_TRANSACTION;
    l_namespace registrytable.namespace%TYPE := nvl(p_namespace,
                                                    pkg_namespace);
    l_envir     registrytable.envir%TYPE := nvl(p_envir, pkg_envir);
  BEGIN
    lv_proc_name := 'insert_value';
    INSERT INTO registrytable
      (namespace, envir, NAME, immutable, VALUE)
    VALUES
      (l_namespace, l_envir, p_name, p_immutable, p_value);
    RETURN TRUE;
  EXCEPTION
    WHEN dup_val_on_index THEN
      RETURN FALSE;
    WHEN OTHERS THEN
      dbadmin.audit_pkg.log_error(lc_svn_id,
                                lv_proc_name,
                                lv_comment,
                                p_name || ' ' || p_value || ' ' ||
                                p_namespace || ' ' || p_envir,
                                $$PLSQL_UNIT,
                                $$PLSQL_LINE,
                                SQLCODE,
                                SQLERRM);
  END insert_value;

  FUNCTION update_value(p_name      VARCHAR2,
                        p_value     VARCHAR2,
                        p_namespace VARCHAR2 DEFAULT NULL,
                        p_envir     VARCHAR2 DEFAULT NULL) RETURN INTEGER IS
    PRAGMA AUTONOMOUS_TRANSACTION;
    l_namespace registrytable.namespace%TYPE := nvl(p_namespace,
                                                    pkg_namespace);
    l_envir     registrytable.envir%TYPE := nvl(p_envir, pkg_envir);
  BEGIN
    lv_proc_name := 'update_value';
    UPDATE registrytable
       SET VALUE = p_value
     WHERE namespace = l_namespace
       AND envir = l_envir
       AND NAME = p_name
       AND immutable = 'N';
    RETURN SQL%ROWCOUNT;
  EXCEPTION
    WHEN OTHERS THEN
      dbadmin.audit_pkg.log_error(lc_svn_id,
                                lv_proc_name,
                                lv_comment,
                                p_name || ' ' || p_value || ' ' ||
                                p_namespace || ' ' || p_envir,
                                $$PLSQL_UNIT,
                                $$PLSQL_LINE,
                                SQLCODE,
                                SQLERRM);
  END update_value;

  PROCEDURE set_value(p_name      VARCHAR2,
                      p_value     VARCHAR2,
                      p_namespace VARCHAR2 DEFAULT NULL,
                      p_envir     VARCHAR2 DEFAULT NULL) IS
    l_return BOOLEAN;
  BEGIN
    lv_proc_name := 'set_value';
    IF (update_value(p_name, p_value, p_namespace, p_envir) = 0) THEN
      l_return := insert_value(p_name, p_value, p_namespace, p_envir);
    END IF;
    IF NOT l_return THEN
      dbadmin.audit_pkg.log_error(lc_svn_id,
                                lv_proc_name,
                                'update failed',
                                p_name || ' ' || p_value || ' ' ||
                                p_namespace || ' ' || p_envir,
                                $$PLSQL_UNIT,
                                $$PLSQL_LINE,
                                SQLCODE,
                                SQLERRM);
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      dbadmin.audit_pkg.log_error(lc_svn_id,
                                lv_proc_name,
                                lv_comment,
                                p_name || ' ' || p_value || ' ' ||
                                p_namespace || ' ' || p_envir,
                                $$PLSQL_UNIT,
                                $$PLSQL_LINE,
                                SQLCODE,
                                SQLERRM);
  END set_value;

  PROCEDURE clear_value(p_name      VARCHAR2,
                        p_namespace VARCHAR2 DEFAULT NULL,
                        p_envir     VARCHAR2 DEFAULT NULL) IS
    PRAGMA AUTONOMOUS_TRANSACTION;
    l_namespace registrytable.namespace%TYPE := nvl(p_namespace,
                                                    pkg_namespace);
    l_envir     registrytable.envir%TYPE := nvl(p_envir, pkg_envir);
  BEGIN
    lv_proc_name := 'clear_value';
    DELETE FROM registrytable
     WHERE namespace = l_namespace
       AND envir = l_envir
       AND NAME = p_name
       AND immutable = 'N';
  EXCEPTION
    WHEN OTHERS THEN
      dbadmin.audit_pkg.log_error(lc_svn_id,
                                lv_proc_name,
                                lv_comment,
                                p_name || ' ' || p_namespace || ' ' ||
                                p_envir,
                                $$PLSQL_UNIT,
                                $$PLSQL_LINE,
                                SQLCODE,
                                SQLERRM);
  END clear_value;

BEGIN
  audit_pkg.log_pkg_init($$PLSQL_UNIT, lc_svn_id);
END registry;
/
SHOW ERRORS
