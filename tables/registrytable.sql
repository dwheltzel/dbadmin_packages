-- File registrytable.sqL
-- Author: dheltzel

create table REGISTRYTABLE_T
(
  NAMESPACE VARCHAR2(30) NOT NULL,
  ENVIR VARCHAR2(30) NOT NULL,
  NAME VARCHAR2(30) NOT NULL,
  IMMUTABLE VARCHAR2(3) DEFAULT 'N',
  VALUE VARCHAR2(300),
  CREATE_DATE DATE DEFAULT sysdate,
  CREATE_USER VARCHAR2(30) DEFAULT USER,
  UPDATE_DATE DATE DEFAULT sysdate,
  UPDATE_USER VARCHAR2(30) DEFAULT USER
);

comment on table REGISTRYTABLE_T is 'Generic Key/value pairs';
comment on column REGISTRYTABLE_T.NAMESPACE is 'This is used to define a private group of records specific to your app, set this in all your packages execute section with a constant value stored in the main package spec';
comment on column REGISTRYTABLE_T.ENVIR is 'This allows different values for different databases, Prod, QA, Dev, for ex';
comment on column REGISTRYTABLE_T.NAME is 'The name of the record';
comment on column REGISTRYTABLE_T.IMMUTABLE is 'Set this to Y and the procs will not allow update or deletion of this record';
comment on column REGISTRYTABLE_T.VALUE is 'The value to return from the GET_VALUE proc';
comment on column REGISTRYTABLE_T.CREATE_DATE is 'When this record was created';
comment on column REGISTRYTABLE_T.CREATE_USER is 'Who created this record';
comment on column REGISTRYTABLE_T.UPDATE_DATE is 'When this record was last updated';
comment on column REGISTRYTABLE_T.UPDATE_USER is 'Who last updated this record';

alter table REGISTRYTABLE_T add constraint REGISTRYTABLE_PK primary key (NAMESPACE, ENVIR, NAME);

CREATE OR REPLACE VIEW REGISTRYTABLE AS select * from REGISTRYTABLE_T;
