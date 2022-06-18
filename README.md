# Find suspicious orphaned file in PostgreSQL data directory

This command, `pg_find_orphaned_file` compared all the database filenode and actual files in the database directory and finds suspicious orphaned files in the data directory.

The algorithm of this inspection is straight forward.  Take a look at the command itself, `pg_find_orphaned_file`.  This is actually bash script and there are nothing special in the command.

## Command option

**`-h host`** specifies host name of the target database,

**`-p port`** specifies port number to conect to the target database,

**`-U username`** or **`-u username`** specifies database user name to connet to the database.   This user must have privlledge to readd all `pg_class` tuples for all the database except for `template0`.

**`-d database`** Specifies database name to login to get list of databases.   Please note that to obtain information of each database, this toll will use such dagtabase name to login.   Database user as specified by `-U` or `-u` option must have proper priviledes to read `pg_class` catalog of each database.

If any of these options are omitted, default value will be used.   If a password is associated with the user, you will be prompted for the password each time this tool connects to the database.   You can bypass this by configuring `.pgpass` file as described in `psql` documentation of PosgtgreSQL.

## Output from the command

Output from the command is lines of suspicious orphaned file found in `$PGDATA` directory.   Each line contains single file path relative from `$PGDATA` directory.

Before removing these files, pleases make sure that you absolutely do not need these files.   It will be a good idea to back up such files in other places to see this is not needed by the database.

If no such suspicious orphaned file is not detected, the command will write this message.

