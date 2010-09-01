#! /bin/sh
REBOOT=0
VERSION="20100901.001"
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
	echo "-owning files."
	chown -R root:root /tmp/upgrade/*
fi

#kernel modules exist
if [ -e /tmp/upgrade/lib/modules ]; then
	echo -n "-remove old modules... "
	/usr/bin/rm -rf /lib/modules/* 
	echo "done."
	echo -n "-install new kernel modules... "
	/usr/bin/cp -a /tmp/upgrade/lib/* /lib
	/sbin/depmod
	echo "done."
	/usr/bin/rm -rf lib
	REBOOT=1
fi

#kernel exist
if [ -e /tmp/upgrade/boot/vmlinuz ]; then
	echo -n "-install new kernel... "
	/usr/bin/rm -rf /boot/*
	/usr/bin/cp -a /tmp/upgrade/boot/* /boot
	/sbin/lilo
	/usr/bin/rm -rf boot/*
	echo "done."
	REBOOT=1
fi

#copy other files
cd /tmp/upgrade
echo "-remove old scripts and modules."
/usr/bin/rm -rf /usr/bin/dt/*
/usr/bin/rm -rf /var/www/*
echo "-copying files... "
/usr/bin/cp -a /tmp/upgrade/* /
echo "-done."


rm -rf /tmp/package.tar.bz2
if [ $REBOOT -eq 1 ]; 
then
	echo "Upgrade complete.  Rebooting."
	/sbin/reboot
else
	echo "Upgrade complete.  Reboot not needed."
	echo ""
fi

#done
