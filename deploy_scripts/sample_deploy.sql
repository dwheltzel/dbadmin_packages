-- Author: dheltzel

--BEGIN
--  deploy_utils.initialize_deploy('10.40', '$Id: create_registry.sql 3382 2014-03-19 15:19:37Z dheltzel $')
--END;
--/

BEGIN
  deploy_utils.deploy_new_table(p_ticket => 'CRQ-99999', p_table_owner => USER, p_table_name => 'REGISTRYTABLE', p_sql => 'create table REGISTRYTABLE
( NAMESPACE VARCHAR2(30) not null,
  ENVIR VARCHAR2(30) not null,
  NAME VARCHAR2(30) not null,
  IMMUTABLE VARCHAR2(3) default ''N'',
  VALUE VARCHAR2(30),
  CREATE_TS TIMESTAMP(6) default sysdate,
  CREATE_USER VARCHAR2(30) default USER,
  UPDATE_TS TIMESTAMP(6) default sysdate,
  UPDATE_USER VARCHAR2(30) default USER,
  CONSTRAINT PK_REGISTRYTABLE PRIMARY KEY (NAMESPACE,ENVIR,NAME)
)', p_comment => 'Generic Key/value pairs');
END;
/

BEGIN audit_pkg.log_ddl_change(p_object_owner => USER, p_object_name => 'REGISTRY', p_object_type => 'PACKAGE', p_parent_name => '', p_ticket => 'CRQ-99999', p_sql_executed => '', p_message => 'Creating package', p_svn_id => 'create_registry.sql dheltzel'); END;
/

@packages/registry_spec.sql
--@packages/registry_other.sql
@packages/registry_body.sql
