#! /bin/sh

echo "Upgrade executed"
#make dir
echo "-cleaning and creating tmp dirs"
/usr/bin/rm -rf /tmp/upgrade
/usr/bin/mkdir /tmp/upgrade

#change to dir
cd /tmp/upgrade

#extract files
echo -n "-extracting files..."
/usr/bin/tar jxf /tmp/package.tar.bz2
echo "done."

#copy files
echo -n "copying files... "
/usr/bin/cp -a * /
echo "done."

/sbin/lilo

echo "-Upgrade complete"

#done
