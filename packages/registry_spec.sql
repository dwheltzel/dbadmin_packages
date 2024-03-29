SET DEFINE OFF

CREATE OR REPLACE PACKAGE registry IS

  -- File registry_spec.sql
  -- Author: dheltzel
  -- Create Date 2013-11-20
  /*  Purpose : Provide generic but flexible access to key-values pairs
  
    Namespace - Developer defined, these exist as they are used. Be sure to pick something that will be unique to your project
      Default namespace is "DEFAULT", but you are strongly encouraged to use your own.
    Environment - Allow for developer defined environments. Here are some example uses:
       Dev/QA/Stage/Prod
       hostname
       Client_no's
  
    Key/value pairs must be unique within namespace and environment. Namespaces allow you to have a "private" set of data
     for multiple environments.
  
  */
  FUNCTION get_namespace RETURN VARCHAR2;

  PROCEDURE set_namespace(p_namespace VARCHAR2);

  PROCEDURE clear_namespace;

  FUNCTION get_environment RETURN VARCHAR2;

  PROCEDURE set_environment(p_envir VARCHAR2);

  PROCEDURE clear_environment;

  FUNCTION get_value(p_name      VARCHAR2,
                     p_namespace VARCHAR2 DEFAULT NULL,
                     p_envir     VARCHAR2 DEFAULT NULL,
                     p_default   VARCHAR2 DEFAULT NULL) RETURN VARCHAR2;

  FUNCTION insert_value(p_name      VARCHAR2,
                        p_value     VARCHAR2,
                        p_namespace VARCHAR2 DEFAULT NULL,
                        p_envir     VARCHAR2 DEFAULT NULL,
                        p_immutable VARCHAR2 DEFAULT 'N') RETURN BOOLEAN;

  FUNCTION update_value(p_name      VARCHAR2,
                        p_value     VARCHAR2,
                        p_namespace VARCHAR2 DEFAULT NULL,
                        p_envir     VARCHAR2 DEFAULT NULL) RETURN INTEGER;

  PROCEDURE set_value(p_name      VARCHAR2,
                      p_value     VARCHAR2,
                      p_namespace VARCHAR2 DEFAULT NULL,
                      p_envir     VARCHAR2 DEFAULT NULL);

  PROCEDURE clear_value(p_name      VARCHAR2,
                        p_namespace VARCHAR2 DEFAULT NULL,
                        p_envir     VARCHAR2 DEFAULT NULL);

END registry;
/
SHOW ERRORS
