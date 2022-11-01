-- File registrytable.sql
-- Author: dheltzel
-- Create Date: 2014-01-03

create table REGISTRYTABLE
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

comment on table REGISTRYTABLE is 'Generic Key/value pairs';

