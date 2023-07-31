-- drop_registry.sql
-- Author: dheltzel

BEGIN
  deploy_utils.drop_object(p_ticket => 'CRQ-99999', p_type => 'PACKAGE', p_owner => USER, p_name => 'REGISTRY');
  deploy_utils.drop_object(p_ticket => 'CRQ-99999', p_type => 'TABLE', p_owner => USER, p_name => 'REGISTRYTABLE');
END;
/
