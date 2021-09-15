# dbadmin_packages
The files here deploy a set of objects to make SQL deploys re-runnable and provide customized auditing for code elevations (and other uses).

tables - contains the DDL to create the tables and associated objects
packages - contains the source for all the packages
editioning_view - not used unless EBR is in use
deploy_scripts - SQL scripts to deploy the objects and also to rollback (remove them)

Deploy scripts:
create_schema - creates the parent schema, DBADMIN, and grants permissions
create_base - installs the tables and packages
drop_base - drops the tables and packages
create_registry - sample program that uses the procedures in the base packages to install a new system
drop_registry - drops the tables and packages for the registry system, using the base packages
VerifyDeployUtils.sql - this runs the package's test routine to identify the version installed

The REGISTRY package implements a flexible key-value store similar to the Windows registry hive. It is entirely separate from the deploy and audit packages and provided her as an example of how to deploy with those packages.
