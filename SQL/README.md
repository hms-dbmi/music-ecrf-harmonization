# SQL queries to generate data

This folder contains SQL queries to access BCH data

---------------

SQL table naming conventions:
When new versions of tables are created, "\_stable" is appended to the table name. 
For example, if a new version of table_a is created, the older version (assumed to be error-free) is saved as table_a_stable, and the newer version keeps the name table_a. 
This way, if we need to revert to a prior table we will have a stable version available.
