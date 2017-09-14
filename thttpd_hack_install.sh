#!/bin/sh

# Last update: URL's Changed

BASEDIR=`dirname $0`

server2="https://github.com/Gusher123/EasyInstall/raw/master"

touch $BASEDIR/install.log

if [ -d /data/hack/www ]
then
   echo thttpd hack already installed | tee $BASEDIR/install.log
   exit
else
#	clear
	echo Starting the installation of the thttpd hack | tee $BASEDIR/install.log
	echo Copying Boxee cgi scripts to /data/hack/www | tee -a $BASEDIR/install.log
	mkdir /data/hack/www 2>&1 | tee -a $BASEDIR/install.log
	cp /opt/local/www/* /data/hack/www/ 2>&1 | tee -a $BASEDIR/install.log
	echo Downloading the hack to /tmp/thttpd_hack | tee -a $BASEDIR/install.log
	mkdir /tmp/thttpd_hack 2>&1 | tee -a $BASEDIR/install.log
	curl -L $server2/boxee_hacks_thttpd4.zip -o /tmp/thttpd_hack/boxee_hacks_thttpd4.zip 2>/dev/null
	curl -L $server2/boxee_hacks_thttpd4.md5 -o /tmp/thttpd_hack/boxee_hacks_thttpd4.md5 2>/dev/null
	md5_1=$(md5sum /tmp/thttpd_hack/boxee_hacks_thttpd4.zip | awk '{print $1}')
	md5_2=$(awk '{print $1}' "/tmp/thttpd_hack/boxee_hacks_thttpd4.md5")
	echo "MD5 of zip: $md5_1" | tee -a $BASEDIR/install.log
	echo "MD5 needed: $md5_2" | tee -a $BASEDIR/install.log
	if [ "$md5_1" != "$md5_2" ] ; then
        	echo "MD5s do not match, aborting"  | tee -a $BASEDIR/install.log
		exit
	fi
	echo Unzipping the hack files | tee -a $BASEDIR/install.log
	unzip /tmp/thttpd_hack/boxee_hacks_thttpd4.zip -d /tmp/thttpd_hack 2>&1 | tee -a $BASEDIR/install.log
	echo Installing the hack to /data/hack/www/ and fixing the permissions | tee -a $BASEDIR/install.log
	mv /tmp/thttpd_hack/*.cgi /data/hack/www/ 2>&1 | tee -a $BASEDIR/install.log
	chmod 777 /data/hack/www/index.cgi 2>&1 | tee -a $BASEDIR/install.log
	mv /tmp/thttpd_hack/thttpd.conf /data/hack/www/ 2>&1 | tee -a $BASEDIR/install.log
	mv /tmp/thttpd_hack/thttpd_hack_uninstall.sh /data/hack/www/ 2>&1 | tee -a $BASEDIR/install.log
	echo Adding the startup script to /data/hack/init.d/ and fixing the permissions | tee -a $BASEDIR/install.log
	mv /tmp/thttpd_hack/23thttpd.sh /data/hack/init.d/ 2>&1 | tee -a $BASEDIR/install.log
	chmod 777 /data/hack/init.d/23thttpd.sh 2>&1 | tee -a $BASEDIR/install.log
	echo Adding links
	ln -s /tmp/root-boxee.log /data/hack/www/
	ln -s /tmp/thttpd.log /data/hack/www/
	ln -s /data/hack/install.log /data/hack/www/hacks_install.log
	ln -s /tmp/mnt/xbmc/portable_data/temp/kodi.log /data/hack/www/xbmc.log
	echo Cleaning up... | tee -a $BASEDIR/install.log
#	rm /tmp/thttpd_hack/boxee_hacks_thttpd4.zip 2>&1 | tee -a $BASEDIR/install.log
#	rm /tmp/thttpd_hack/boxee_hacks_thttpd4.md5 2>&1 | tee -a $BASEDIR/install.log
	rm /tmp/thttpd_hack/* 2>&1 | tee -a $BASEDIR/install.log
	rmdir /tmp/thttpd_hack 2>&1 | tee -a $BASEDIR/install.log
	echo Binding and restarting thttpd | tee -a $BASEDIR/install.log
	mount -o bind /data/hack/www/thttpd.conf /etc/thttpd.conf
	killall thttpd 2>&1| tee -a $BASEDIR/install.log
	mv $BASEDIR/install.log /data/hack/www/
fi