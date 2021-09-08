-- File $Id: registrytable.sql 2002 2014-01-03 20:55:45Z dheltzel $
-- Modified $Author: dheltzel $ 
-- Date $Date: 2014-01-03 15:55:45 -0500 (Fri, 03 Jan 2014) $
-- Revision $Revision: 2002 $

create table DBADMIN.REGISTRYTABLE
(
  NAMESPACE VARCHAR2(30) NOT NULL,
  ENVIR VARCHAR2(30) NOT NULL,
  NAME VARCHAR2(30) NOT NULL,
  IMMUTABLE VARCHAR2(3) default 'N',
  VALUE VARCHAR2(30),
  CREATE_TS TIMESTAMP(6) default sysdate,
  CREATE_USER VARCHAR2(30) default USER,
  UPDATE_TS TIMESTAMP(6) default sysdate,
  UPDATE_USER VARCHAR2(30) default USER
);

comment on table DBADMIN.REGISTRYTABLE is 'Generic Key/value pairs';

