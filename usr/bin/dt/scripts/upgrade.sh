#! /bin/sh

echo "Upgrade executed"

#make dir
echo ""
echo "-cleaning and creating tmp dirs"
/usr/bin/rm -rf /tmp/upgrade
/usr/bin/mkdir /tmp/upgrade

#change to dir
cd /tmp/upgrade

#extract files
if [ -e /tmp/package.tar.bz2 ]; then
	echo ""
	echo -n "-extracting files..."
	/usr/bin/tar jxfm /tmp/package.tar.bz2
	echo "done."
fi

#kernel modules exist
if [ -e /tmp/upgrade/lib/modules ]; then
	echo ""
	echo -n "-remove old modules... "
	/usr/bin/rm -rf /lib/modules/* 
	echo "done."
	echo ""
	echo -n "Install new kernel modules... "
  /usr/bin/cp -a /tmp/upgrade/lib/* /lib
  /sbin/depmod
  echo "done."
  /usr/bin/rm -rf lib
fi

#kernel exist
if [ -e /tmp/upgrade/boot/vmlinuz ]; then
	echo ""
	echo -n "-install new kernel... "
	/usr/bin/rm -rf /boot/*
  /usr/bin/cp -a /tmp/upgrade/boot/* /boot
	/sbin/lilo
	/usr/bin/rm -rf boot/*
	echo "done."
fi

#copy other files
if [ -e .version ]; then
	echo ""
	echo -n "-copying files... "
	/usr/bin/cp -a * /
	/usr/bin/cp /tmp/upgrade/.version /.version
	/usr/bin/cp /tmp/upgrade/.model /.model
	echo "done."
fi


echo ""
echo "Upgrade complete.  Reboot."
rm -rf /tmp/package.tar.bz2
/sbin/reboot

#done
