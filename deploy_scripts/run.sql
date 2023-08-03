PROMPT Main script to create the new schema and populate it.

DEFINE schema_name = 'TEST_ADMIN'
DEFINE schema_pass = 'nwh4ueSuTr1l'

@deploy_scripts/create_schema.sql &&schema_name &&schema_pass

ALTER SESSION SET CURRENT_SCHEMA=&&schema_name;

@deploy_scripts/create_base.sql &&schema_name


