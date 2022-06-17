#!/bin/bash

# Scan all the file path and actual file to extract suspicious orphaned file
# in the database file system.
#
# Command argument should be connection string to the database.   If omitted,
# default connecton will be used.
#
# The user must have privellege to all the databases, hopefully superusser.


conninfo="$*"
dbdirinfo=data_directory.out
dblist=dblist.out
pathlist=pathlist.out
filelist=filelist.out
wkout=wkout.out

if [[ "$conninfo" == "" ]]
then
	connstr=""
else
	connstr="-d $conninfo"
fi

rm -f $pathlist
touch $pathlist

allsafe="yes"

# Get database directory

psql -q -t -o $dbdirinfo "$connstr" -c "SHOW data_directory" > /dev/null

read dbpath < $dbdirinfo
rm -f $dbdirinfo

# Get database list other than template0

psql -q -t -o $dblist "$connstr" -c "select datname from pg_database where datname <> 'template0'" > /dev/null

# Get filepath for all the relations.
# Note to track symlink for tablespaces

for db in `cat $dblist`
do
	psql -q -t -o $wkout "$connstr" -d $db -c 'select pg_relation_filepath(oid) from pg_class where pg_relation_filepath(oid) is not null' > /dev/null
	cat $wkout >> $pathlist
done
sort $pathlist | sed '/^[	]*$/d' | uniq > $pathlist.wk
cp $pathlist.wk $pathlist
rm $pathlist.wk
rm $wkout

# Get all the file list for all the databases
# Note to track symlink for tablespaces

psql -q -t -o $wkout "$connstr" -c "select pg_ls_dir('global')" > /dev/null
sed '/^[   ]*$/d' $wkout | sed 's/^ */global\//' > $filelist

psql -q -t -o $dblist "$connstr" -c "select oid from pg_database where datname <> 'template0'" > /dev/null
for db in `cat $dblist`
do
	psql -q -t -o $wkout "$connsts" -c "select pg_ls_dir('base/$db')" > /dev/null
	sed '/^[   ]*$/d' $wkout | sed "s/^ */base\/$db\//" >> $filelist
done

sort $filelist | sed '/^[	]*$/d' | uniq > $filelist.wk
cp $filelist.wk $filelist
rm $filelist.wk

# Now materials are ready

flag="no"

while read fileline
do
    if [[ `basename $fileline` == "pg_internal.init" ]]
    then
        continue
	fi
    if [[ `basename $fileline` == "pg_filenode.map" ]]
    then
        continue
    fi
    if [[ $fileline =~ ^global/.*$ ]] && [[ `basename $fileline` == "pg_control" ]]
    then
        continue
    fi
    if [[ $fileline =~ ^base/.*$ ]] && [[ `basename $fileline` == "PG_VERSION" ]]
    then
        continue
    fi
	flag="no"
    while read pathline
    do
        if [[ "$fileline" == "$pathline" ]]
        then
            flag="yes"
			break
        fi
        newpattern="${pathline}_fsm"
        if [[ "$fileline" == $newpattern ]]
        then
            flag="yes"
			break
        fi
        newpattern="${pathline}_vm"
        if [[ "$fileline" == "$newpattern" ]]
        then
            flag="yes"
			break
        fi
        regexp="^${pathline}.[0-9]+$"
        if [[ "$fileline" =~ $regexp ]]
        then
            flag="yes"
			break
        fi
    done < $pathlist

    if [[ $flag == "no" ]]
    then
		allsafe="no"
        echo "Suspicious: " $fileline
    fi

done < $filelist

if [[ "$allsafe" == "yes" ]]
then
	echo "No suspicious orphaned file found."
fi

rm $pathlist
rm $filelist
rm $dblist