SET DEFINE OFF

CREATE OR REPLACE PACKAGE PKG_DEPLOY_UTILS
-- Author: dheltzel
AUTHID CURRENT_USER AS

  /* Utility programs for deployments
  These are all run with INVOKER rights, not as the ADMIN user
  */

  -- This is the table we look for to get the list of cust schemas
  cust_sch_indicator_tab CONSTANT VARCHAR2(20) := 'USERS_AUDIT';

  -- Name of the schema for the backup data
  backup_schema CONSTANT VARCHAR2(20) := 'DBADMIN';

  -- Name of the schema for the customer sequences
  cust_seq_schema CONSTANT VARCHAR2(20) := 'BOMS';

  TYPE cust_schema_typ IS TABLE OF VARCHAR2(35) INDEX BY BINARY_INTEGER;
  cust_schema_tab cust_schema_typ;

  -- Current elevation release and revision
  current_release  VARCHAR2(50);
  current_revision VARCHAR2(50);

  -- Prints info from this package, useful as a unit test to validate the version that is installed
  PROCEDURE pkg_info;

  -- Get and/or Set Debug Level
  FUNCTION get_set_debug_level(new_debug_lvl IN INTEGER DEFAULT NULL) RETURN INTEGER;

  -- This will setup package variables and create an initial log entry for the deploy
  PROCEDURE initialize_deploy(p_ticket       VARCHAR,
                              p_release_name VARCHAR2,
                              p_svn_revision VARCHAR2,
                              p_svn_id       VARCHAR2);

  -- returns package vars, use in selects
  FUNCTION get_current_release RETURN VARCHAR2;
  FUNCTION get_current_revision RETURN VARCHAR2;

  -- checka if we should use partitioning
  FUNCTION is_partitioned_db RETURN BOOLEAN;

  -- generic logger proc
  PROCEDURE log_deploy_info(p_name VARCHAR2, p_svn_id VARCHAR2);

  -- populate the customer schema list (schemas that own a table called $cust_sch_indicator_tab
  PROCEDURE pop_cust_schema_tab;

  -- unit test for pop_cust_schema_tab, prints list of cust schemas
  PROCEDURE list_cust_schemas;

  -- Updates rows in a table in "chunks" with a commit between each update
  -- This is a very efficient and controllable way to do mass updateson a live database
  -- Example for p_update_sql:
  -- 'UPDATE /*+ ROWID (dda) */ order_items_ SET unit_amount_new = unit_amount WHERE rowid BETWEEN :start_id AND :end_id and unit_amount_new IS NULL';
  PROCEDURE update_rows(p_table_owner VARCHAR,
                        p_table_name  VARCHAR,
                        p_update_sql  VARCHAR,
                        p_chunk_size  PLS_INTEGER DEFAULT 5000);

  /* deploy_ procedures - these are used in elevation scripts to create or update objects in a re-runnable way.
  - check for the existance of the object before trying to create it.
  - log audit info and any exceptions
  - optional p_partitioned_sql parameter for partitionable objects will only be used when the db supports partitions (as defined in the is_partitioned_db func)
  These may someday have a corresponding proc to perform the operation across all the cust schemas with a single call
  */
  PROCEDURE deploy_new_schema(p_ticket VARCHAR, p_schema VARCHAR, p_comment VARCHAR DEFAULT NULL);

  PROCEDURE deploy_new_table(p_ticket          VARCHAR,
                             p_table_owner     VARCHAR,
                             p_table_name      VARCHAR,
                             p_sql             VARCHAR,
                             p_partitioned_sql VARCHAR DEFAULT NULL,
                             p_comment         VARCHAR DEFAULT NULL);

  PROCEDURE deploy_new_column(p_ticket      VARCHAR,
                              p_table_owner VARCHAR,
                              p_table_name  VARCHAR,
                              p_col_name    VARCHAR,
                              p_sql         VARCHAR,
                              p_comment     VARCHAR DEFAULT NULL);

  PROCEDURE deploy_new_index(p_ticket          VARCHAR,
                             p_table_owner     VARCHAR,
                             p_table_name      VARCHAR,
                             p_index_name      VARCHAR,
                             p_sql             VARCHAR,
                             p_partitioned_sql VARCHAR DEFAULT NULL,
                             p_comment         VARCHAR DEFAULT NULL);

  PROCEDURE deploy_new_sequence(p_ticket   VARCHAR,
                                p_owner    VARCHAR,
                                p_seq_name VARCHAR,
                                p_sql      VARCHAR DEFAULT NULL,
                                p_comment  VARCHAR DEFAULT NULL);

  -- This creates a sequence in the MDM schema and then makes select grants to all customer schemas
  -- Passing the create DDL is optional, but if you do, be sure to specify MDM as the schemaa
  PROCEDURE deploy_new_sequence_cust(p_ticket   VARCHAR,
                                     p_seq_name VARCHAR,
                                     p_sql      VARCHAR DEFAULT NULL,
                                     p_comment  VARCHAR DEFAULT NULL);

  PROCEDURE deploy_new_constraint(p_ticket          VARCHAR,
                                  p_table_owner     VARCHAR,
                                  p_table_name      VARCHAR,
                                  p_constraint_name VARCHAR,
                                  p_sql             VARCHAR,
                                  p_comment         VARCHAR DEFAULT NULL);

  PROCEDURE deploy_new_job(p_ticket   VARCHAR,
                           p_owner    VARCHAR,
                           p_job_name VARCHAR,
                           p_sql      VARCHAR,
                           p_comment  VARCHAR DEFAULT NULL);

  PROCEDURE deploy_alter_column(p_ticket      VARCHAR,
                                p_table_owner VARCHAR,
                                p_table_name  VARCHAR,
                                p_col_name    VARCHAR,
                                p_sql         VARCHAR,
                                p_comment     VARCHAR DEFAULT NULL);

  -- This is not for general use, always prefer to use the procs above
  PROCEDURE deploy_ddl(p_ticket VARCHAR, p_sql VARCHAR, p_comment VARCHAR DEFAULT NULL);

  -- Procedure to safely drop objects
  -- If the p_sql is not provided, it will attempt to create the drop statement for you. This usually works and is easier.
  PROCEDURE drop_object(p_ticket  VARCHAR,
                        p_type    VARCHAR,
                        p_owner   VARCHAR,
                        p_name    VARCHAR,
                        p_sql     VARCHAR DEFAULT NULL,
                        p_comment VARCHAR DEFAULT NULL);

  /* Return a consistent table name for the backup process
  Can be called later with the same ticket number to return the name of the backup table originally created
  Call as function or proc, the proc will output to dbms_output
  */
  FUNCTION backup_table_name(p_ticket VARCHAR, p_table_owner VARCHAR, p_table_name VARCHAR)
    RETURN VARCHAR;

  PROCEDURE backup_table_name(p_ticket VARCHAR, p_table_owner VARCHAR, p_table_name VARCHAR);

  /* deploy_utils.backup_data
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
  PROCEDURE backup_data(p_ticket      VARCHAR,
                        p_table_owner VARCHAR,
                        p_table_name  VARCHAR,
                        p_sql         VARCHAR DEFAULT NULL,
                        p_expire_date DATE DEFAULT NULL,
                        p_comment     VARCHAR DEFAULT NULL);

  -- trim_backup_data - trims the backup data if it is past it's expire date
  -- the force option ignores the expiration date and always drops the data
  PROCEDURE trim_backup_data(p_ticket      VARCHAR,
                              p_table_owner VARCHAR,
                              p_table_name  VARCHAR,
                              force         BOOLEAN DEFAULT FALSE);

END PKG_DEPLOY_UTILS;
/
SHOW ERRORS
