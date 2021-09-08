-- File $Id: drop_registry.sql 2036 2014-01-06 15:22:31Z dheltzel $
-- Modified $Author: dheltzel $ 
-- Date $Date: 2014-01-06 10:22:31 -0500 (Mon, 06 Jan 2014) $
-- Revision $Revision: 2036 $

BEGIN
  dbadmin.deploy_utils.drop_object(p_ticket => 'CRQ-99999', p_type => 'PACKAGE', p_owner => 'DBADMIN', p_name => 'REGISTRY');
  dbadmin.deploy_utils.drop_object(p_ticket => 'CRQ-99999', p_type => 'TABLE', p_owner => 'DBADMIN', p_name => 'REGISTRYTABLE');
END;
/
