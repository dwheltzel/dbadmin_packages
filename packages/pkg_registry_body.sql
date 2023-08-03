CREATE OR REPLACE PACKAGE BODY PKG_REGISTRY IS
  -- Author: dheltzel
  LC_SVN_ID VARCHAR2(200) := 'registry_body.sql dheltzel';

  LV_PROC_NAME ERR_LOG.PROC_NAME%TYPE;

  LV_COMMENT ERR_LOG.SOURCE_FILE%TYPE := 'Starting';

  PKG_NAMESPACE REGISTRYTABLE.NAMESPACE%TYPE := 'DEFAULT';

  PKG_ENVIR REGISTRYTABLE.ENVIR%TYPE := 'A';

  FUNCTION GET_NAMESPACE RETURN VARCHAR2 IS
  BEGIN
    LV_PROC_NAME := 'get_namespace';
    RETURN(PKG_NAMESPACE);
  EXCEPTION
    WHEN OTHERS THEN
      PKG_AUDIT.LOG_ERROR(LC_SVN_ID,
                          LV_PROC_NAME,
                          LV_COMMENT,
                          PKG_NAMESPACE,
                          $$PLSQL_UNIT,
                          $$PLSQL_LINE,
                          SQLCODE,
                          SQLERRM);
  END GET_NAMESPACE;

  PROCEDURE SET_NAMESPACE(P_NAMESPACE VARCHAR2) IS
  BEGIN
    LV_PROC_NAME  := 'set_namespace';
    PKG_NAMESPACE := P_NAMESPACE;
  EXCEPTION
    WHEN OTHERS THEN
      PKG_AUDIT.LOG_ERROR(LC_SVN_ID,
                          LV_PROC_NAME,
                          LV_COMMENT,
                          P_NAMESPACE,
                          $$PLSQL_UNIT,
                          $$PLSQL_LINE,
                          SQLCODE,
                          SQLERRM);
  END SET_NAMESPACE;

  PROCEDURE CLEAR_NAMESPACE IS
  BEGIN
    LV_PROC_NAME  := 'clear_namespace';
    PKG_NAMESPACE := 'DEFAULT';
  EXCEPTION
    WHEN OTHERS THEN
      PKG_AUDIT.LOG_ERROR(LC_SVN_ID,
                          LV_PROC_NAME,
                          LV_COMMENT,
                          PKG_NAMESPACE,
                          $$PLSQL_UNIT,
                          $$PLSQL_LINE,
                          SQLCODE,
                          SQLERRM);
  END CLEAR_NAMESPACE;

  FUNCTION GET_ENVIRONMENT RETURN VARCHAR2 IS
  BEGIN
    LV_PROC_NAME := 'get_environment';
    RETURN(PKG_ENVIR);
  EXCEPTION
    WHEN OTHERS THEN
      PKG_AUDIT.LOG_ERROR(LC_SVN_ID,
                          LV_PROC_NAME,
                          LV_COMMENT,
                          PKG_ENVIR,
                          $$PLSQL_UNIT,
                          $$PLSQL_LINE,
                          SQLCODE,
                          SQLERRM);
  END GET_ENVIRONMENT;

  PROCEDURE SET_ENVIRONMENT(P_ENVIR VARCHAR2) IS
  BEGIN
    LV_PROC_NAME := 'set_environment';
    PKG_ENVIR    := P_ENVIR;
  EXCEPTION
    WHEN OTHERS THEN
      PKG_AUDIT.LOG_ERROR(LC_SVN_ID,
                          LV_PROC_NAME,
                          LV_COMMENT,
                          PKG_ENVIR,
                          $$PLSQL_UNIT,
                          $$PLSQL_LINE,
                          SQLCODE,
                          SQLERRM);
  END SET_ENVIRONMENT;

  PROCEDURE CLEAR_ENVIRONMENT IS
  BEGIN
    LV_PROC_NAME := 'clear_environment';
    PKG_ENVIR    := 'A';
  EXCEPTION
    WHEN OTHERS THEN
      PKG_AUDIT.LOG_ERROR(LC_SVN_ID,
                          LV_PROC_NAME,
                          LV_COMMENT,
                          PKG_ENVIR,
                          $$PLSQL_UNIT,
                          $$PLSQL_LINE,
                          SQLCODE,
                          SQLERRM);
  END CLEAR_ENVIRONMENT;

  FUNCTION GET_VALUE(P_NAME      VARCHAR2,
                     P_NAMESPACE VARCHAR2 DEFAULT NULL,
                     P_ENVIR     VARCHAR2 DEFAULT NULL,
                     P_DEFAULT   VARCHAR2 DEFAULT NULL) RETURN VARCHAR2 IS
    RESULT      VARCHAR2(4000);
    L_NAMESPACE REGISTRYTABLE.NAMESPACE%TYPE := NVL(P_NAMESPACE,
                                                    PKG_NAMESPACE);
    L_ENVIR     REGISTRYTABLE.ENVIR%TYPE := NVL(P_ENVIR, PKG_ENVIR);
  BEGIN
    LV_PROC_NAME := 'get_value';
    -- Select the value with an aggregate function so it returns NULL on no records found
    -- and allows an override to the passed in default if null or not found
    SELECT NVL(MAX(VALUE), P_DEFAULT)
      INTO RESULT
      FROM REGISTRYTABLE
     WHERE NAMESPACE = L_NAMESPACE
       AND ENVIR = L_ENVIR
       AND NAME = P_NAME;
    RETURN(RESULT);
  EXCEPTION
    WHEN OTHERS THEN
      PKG_AUDIT.LOG_ERROR(LC_SVN_ID,
                          LV_PROC_NAME,
                          LV_COMMENT,
                          P_NAME || ' ' || P_NAMESPACE || ' ' || P_ENVIR,
                          $$PLSQL_UNIT,
                          $$PLSQL_LINE,
                          SQLCODE,
                          SQLERRM);
  END GET_VALUE;

  FUNCTION INSERT_VALUE(P_NAME      VARCHAR2,
                        P_VALUE     VARCHAR2,
                        P_NAMESPACE VARCHAR2 DEFAULT NULL,
                        P_ENVIR     VARCHAR2 DEFAULT NULL,
                        P_IMMUTABLE VARCHAR2 DEFAULT 'N') RETURN BOOLEAN IS
    PRAGMA AUTONOMOUS_TRANSACTION;
    L_NAMESPACE REGISTRYTABLE.NAMESPACE%TYPE := NVL(P_NAMESPACE,
                                                    PKG_NAMESPACE);
    L_ENVIR     REGISTRYTABLE.ENVIR%TYPE := NVL(P_ENVIR, PKG_ENVIR);
  BEGIN
    LV_PROC_NAME := 'insert_value';
    INSERT INTO REGISTRYTABLE
      (NAMESPACE, ENVIR, NAME, IMMUTABLE, VALUE)
    VALUES
      (L_NAMESPACE, L_ENVIR, P_NAME, P_IMMUTABLE, P_VALUE);
    RETURN TRUE;
  EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
      RETURN FALSE;
    WHEN OTHERS THEN
      PKG_AUDIT.LOG_ERROR(LC_SVN_ID,
                          LV_PROC_NAME,
                          LV_COMMENT,
                          P_NAME || ' ' || P_VALUE || ' ' || P_NAMESPACE || ' ' ||
                          P_ENVIR,
                          $$PLSQL_UNIT,
                          $$PLSQL_LINE,
                          SQLCODE,
                          SQLERRM);
  END INSERT_VALUE;

  FUNCTION UPDATE_VALUE(P_NAME      VARCHAR2,
                        P_VALUE     VARCHAR2,
                        P_NAMESPACE VARCHAR2 DEFAULT NULL,
                        P_ENVIR     VARCHAR2 DEFAULT NULL) RETURN INTEGER IS
    PRAGMA AUTONOMOUS_TRANSACTION;
    L_NAMESPACE REGISTRYTABLE.NAMESPACE%TYPE := NVL(P_NAMESPACE,
                                                    PKG_NAMESPACE);
    L_ENVIR     REGISTRYTABLE.ENVIR%TYPE := NVL(P_ENVIR, PKG_ENVIR);
  BEGIN
    LV_PROC_NAME := 'update_value';
    UPDATE REGISTRYTABLE
       SET VALUE = P_VALUE
     WHERE NAMESPACE = L_NAMESPACE
       AND ENVIR = L_ENVIR
       AND NAME = P_NAME
       AND IMMUTABLE = 'N';
    RETURN SQL%ROWCOUNT;
  EXCEPTION
    WHEN OTHERS THEN
      PKG_AUDIT.LOG_ERROR(LC_SVN_ID,
                          LV_PROC_NAME,
                          LV_COMMENT,
                          P_NAME || ' ' || P_VALUE || ' ' || P_NAMESPACE || ' ' ||
                          P_ENVIR,
                          $$PLSQL_UNIT,
                          $$PLSQL_LINE,
                          SQLCODE,
                          SQLERRM);
  END UPDATE_VALUE;

  PROCEDURE SET_VALUE(P_NAME      VARCHAR2,
                      P_VALUE     VARCHAR2,
                      P_NAMESPACE VARCHAR2 DEFAULT NULL,
                      P_ENVIR     VARCHAR2 DEFAULT NULL) IS
    L_RETURN BOOLEAN;
  BEGIN
    LV_PROC_NAME := 'set_value';
    IF (UPDATE_VALUE(P_NAME, P_VALUE, P_NAMESPACE, P_ENVIR) = 0) THEN
      L_RETURN := INSERT_VALUE(P_NAME, P_VALUE, P_NAMESPACE, P_ENVIR);
    END IF;
    IF NOT L_RETURN THEN
      PKG_AUDIT.LOG_ERROR(LC_SVN_ID,
                          LV_PROC_NAME,
                          'update failed',
                          P_NAME || ' ' || P_VALUE || ' ' || P_NAMESPACE || ' ' ||
                          P_ENVIR,
                          $$PLSQL_UNIT,
                          $$PLSQL_LINE,
                          SQLCODE,
                          SQLERRM);
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      PKG_AUDIT.LOG_ERROR(LC_SVN_ID,
                          LV_PROC_NAME,
                          LV_COMMENT,
                          P_NAME || ' ' || P_VALUE || ' ' || P_NAMESPACE || ' ' ||
                          P_ENVIR,
                          $$PLSQL_UNIT,
                          $$PLSQL_LINE,
                          SQLCODE,
                          SQLERRM);
  END SET_VALUE;

  PROCEDURE CLEAR_VALUE(P_NAME      VARCHAR2,
                        P_NAMESPACE VARCHAR2 DEFAULT NULL,
                        P_ENVIR     VARCHAR2 DEFAULT NULL) IS
    PRAGMA AUTONOMOUS_TRANSACTION;
    L_NAMESPACE REGISTRYTABLE.NAMESPACE%TYPE := NVL(P_NAMESPACE,
                                                    PKG_NAMESPACE);
    L_ENVIR     REGISTRYTABLE.ENVIR%TYPE := NVL(P_ENVIR, PKG_ENVIR);
  BEGIN
    LV_PROC_NAME := 'clear_value';
    DELETE FROM REGISTRYTABLE
     WHERE NAMESPACE = L_NAMESPACE
       AND ENVIR = L_ENVIR
       AND NAME = P_NAME
       AND IMMUTABLE = 'N';
  EXCEPTION
    WHEN OTHERS THEN
      PKG_AUDIT.LOG_ERROR(LC_SVN_ID,
                          LV_PROC_NAME,
                          LV_COMMENT,
                          P_NAME || ' ' || P_NAMESPACE || ' ' || P_ENVIR,
                          $$PLSQL_UNIT,
                          $$PLSQL_LINE,
                          SQLCODE,
                          SQLERRM);
  END CLEAR_VALUE;

BEGIN
  PKG_AUDIT.LOG_PKG_INIT($$PLSQL_UNIT, LC_SVN_ID);
END PKG_REGISTRY;
/
