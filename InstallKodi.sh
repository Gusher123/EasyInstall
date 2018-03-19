#!/bin/sh

# To run:
# curl -L https://raw.githubusercontent.com/Gusher123/EasyInstall/master/InstallKodi.sh | sh

# Version 2.3 d.d. 19-03-2018

# Multiple changes because of curllibs being outdatd.
# Last update: URL's Changed
# Updated server4 string to latest version busybox 
# Added empty the /download/ directory to make space for the installation
# Use /opt/local/bin/ps specifically for compatability when installing busybox
# Also kill all Kodi software
# Moved dialog to my own server, making this script indendant from http://boxee-kodi.leechburgltc.com/ 
# Fixed not loading of telnetd (grep -i -c)
# Added temporarily open telnetd at port 2323 and open ftpd at port 21
# Added remove this script from the 'Windows Server name' in Boxeebox software
# Fixed stopping XBMC/Kodi from rebooting itself

my_ip=`ifconfig | grep "inet addr" | grep -v "127.0.0.1" | awk '{print $2 }' | cut -f2 -d:`

server="http://boxee-kodi.leechburgltc.com"
server2="https://raw.githubusercontent.com/Gusher123/EasyInstall/master"
server3="http://dl.boxeed.in"
server4="https://busybox.net/downloads/binaries/1.28.1-defconfig-multiarch/busybox-i686"

if [ `uptime| awk '{print $3}'|cut -d',' -f 1|cut -d':' -f 2` -lt 2 ];
then
	echo "Wait for boxee to be completely booted..."
	echo "While waiting, blink the Boxee logo green..."
	while [ `uptime| awk '{print $3}'|cut -d',' -f 1|cut -d':' -f 2` -lt 2 ];
	do
		sleep 1
		# Change logo to green
		dtool 6 2 0 50
		sleep 1
		# Change logo to off
		dtool 6 2 0 0
	done
	echo "Done! Reaching two minutes of uptime. Loading script..."
fi;

echo "Changing the Boxee logo to red until the terminal on HDMI out is ready..."
dtool 6 1 0 100 
dtool 6 2 0 0

echo "Emptying /download/ to make space for the installation..."
cd /download/
for f in /download/*; do
	if [ "${f}" != "/download/xbmc" ]; then
		if ! [ -h "${f}" ]; then
			echo "- Removing ${f}"
			rm -fr "${f}"
		fi
	else
		echo "- NOT Removing ${f}"
	fi
done

if [ `cat /data/etc/boxeehal.conf | grep -i -c tinyurl` -gt 0 ] || [ `cat /data/.boxee/UserData/guisettings.xml | grep -i -c tinyurl` -gt 0 ]
then
	echo "Remove the command that started this script from the 'Windows Server name'"
	/bin/busybox sed -i 's/"hostname":"\([^;]*\);.*","p/"hostname":"\1","p/g' /data/etc/boxeehal.conf
	/bin/busybox sed -i 's/<hostname>\([^;]*\);.*<\/hostname>/<hostname>\1<\/hostname>/g' /data/.boxee/UserData/guisettings.xml
	if [ -f /data/hack/boot.sh ]
	then
		echo "If Boxee+Hacks was installed, reapply command to start Boxee+Hacks at next boot"
		/bin/busybox sed -i 's/","password/;sh \/data\/hack\/boot.sh","password/g' /data/etc/boxeehal.conf
		/bin/busybox sed -i "s/<\/hostname>/;sh \/data\/hack\/boot.sh\<\/hostname>/g" /data/.boxee/UserData/guisettings.xml
		/bin/busybox sed -i "s/<enabled>false/<enabled>true/g" /data/.boxee/UserData/guisettings.xml
	fi
	touch /data/etc/boxeehal.conf
	touch /data/.boxee/UserData/guisettings.xml
fi

# We need to install new curl libraries in tmp/lib/
if [ -f /tmp/lib/libcurl.so.4 ]
then
	echo Libcurl libraries available
else
	echo Libcurl libraries not available, installing them temporarily in /tmp/lib
	echo - Downloading libcurl.zip
	mkdir -p /tmp/libcurl
	curl -L -s $server2/libcurl.zip -o /tmp/libcurl.zip
	echo - Extracting libcurl.zip to /tmp/libcurl/
	unzip -o -q /tmp/libcurl.zip -d /tmp/libcurl/
	echo - Adding /tmp/libcurl/ to LD_LIBRARY_PATH
	export LD_LIBRARY_PATH=/tmp/libcurl:$LD_LIBRARY_PATH
	curl --cacert /opt/local/share/curl/ca-bundle.crt https://curl.haxx.se/ca/cacert.pem -o /tmp/cacert.pem
	export CURL_CA_BUNDLE=/tmp/cacert.pem
fi

# Download a shell that can exist in /tmp/ before Boxee+hacks is installed.
# Also needed in InstallKodi2.sh
curl -L -s $server2/shell_tmp.sh -o /tmp/shell_tmp.sh
chmod 777 /tmp/shell_tmp.sh

if [ `/opt/local/bin/ps -A -F | grep -i -c telnetd` -eq 0 ]
then
	curl -L -s $server4 -o /tmp/busybox
	chmod 777 /tmp/busybox
	echo "Temporarily opening telnetd at $my_ip port 2323" 
	/tmp/busybox telnetd -p 2323 -l /tmp/shell_tmp.sh &
fi

if [ `/opt/local/bin/ps -A -F | grep -i -c ftpd` -eq 0 ]
then
	if [ ! -f /tmp/busybox ]
	then
		curl -L -s $server4 -o /tmp/busybox
		chmod 777 /tmp/busybox
	fi
	echo "Temporarily opening ftpd at $my_ip port 21"
	/usr/bin/nohup /tmp/busybox tcpsvd -vE 0.0.0.0 21 /tmp/busybox ftpd -w / &
fi

echo "Preparing to run the installer on HDMI out" 

# DFBTerm can be eighter avaiable through a mount from /tmp/local_mnt or /data/hack/local_mnt
if [ ! -d /usr/local/DFBTerm ]
then
	echo "DFBTerm not available, installing it temporarily in /tmp/"
	echo "- Downloading DFBTerm.tgz"
	curl -L -s $server2/DFBTerm.tgz -o /tmp/DFBTerm.tgz
	echo "- Extracting DFBTerm.tgz to /tmp/local_mnt/"
	tar -x -f /tmp/DFBTerm.tgz -C /tmp/
	echo "- Copying the original /usr/local/ files to /tmp/local_mnt/"
	cp -R /usr/local/* /tmp/local_mnt/
	echo "- Binding /tmp/local_mnt/ to /usr/local"
	mount -o bind /tmp/local_mnt /usr/local
else
	echo "DFBTerm available"
fi

export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/DFBTerm/lib

# We cannot use dialog from /data/hack/bin because it might get wiped when reinstalling Boxee+Hacks
if [ ! -f /tmp/dialog/dialog ]
then
	echo "Dialog not available, installing it temporarily in /tmp/dialog/"
	echo "- Downloading Dialog"
	mkdir -p /tmp/dialog
	curl -L -s $server2/dialog -o /tmp/dialog/dialog 
	echo "- Installing it to /tmp/dialog/"
	chmod +x /tmp/dialog/dialog
	echo "- Adding /tmp/dialog/ to PATH"
	export PATH=$PATH:/tmp/dialog
else
	echo "Dialog available"
fi

# We need to install the libraries if they are not available in /data/hack/lib or /tmp/lib/
if [ -d /data/hack/lib/ ] || [ -d /tmp/lib/ ]
then
	echo Libraries available
else
	echo Libraries not available, installing them temporarily in /tmp/lib
	echo - Downloading lib.tgz
	mkdir -p /tmp/lib
	curl -L -s $server2/lib.tgz -o /tmp/lib.tgz
	echo - Extracting lib.tgz to /tmp/lib/
	tar -x -f /tmp/lib.tgz -C /tmp/lib/
	echo - Adding /tmp/lib/ to LD_LIBRARY_PATH
	export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/tmp/lib
fi

if [ `/opt/local/bin/ps -A | grep -i -c boxeehal` -eq 1 ] || [ `/opt/local/bin/ps -A | grep -i -c BoxeeLauncher` -eq 1 ]
then
	echo "Killing all Boxeebox software before starting the terminal"
	/etc/rc3.d/U94boxeehal stop
	/etc/rc3.d/U99boxee stop
	killall BoxeeHal
	killall BoxeeLauncher
	killall Boxee
	killall run_boxee.sh
fi

if [ `/opt/local/bin/ps -A | grep -i -c xbmc.bin` -eq 1 ] || [ `/opt/local/bin/ps -A | grep -i -c kodi.bin` -eq 1 ]
then
	echo "Killing all xbmc and kodi software before starting the terminal"
	/opt/local/bin/ps -A -F | grep xbmc | grep -v grep | awk '{print "kill " $2}'|sh
	/opt/local/bin/ps -A -F | grep kodi | grep -v grep | awk '{print "kill " $2}'|sh
fi

echo "Downloading the install script"
curl -L -s $server2/InstallKodi2.sh -o /tmp/InstallKodi2.sh
chmod 777 /tmp/InstallKodi2.sh
curl -L -s $server2/shell_no_password.sh -o /tmp/shell_no_password.sh
chmod 777 /tmp/shell_no_password.sh
#rm -rf /tmp/InstallKodi1.sh
#touch /tmp/InstallKodi1.sh
#echo "sh /tmp/InstallKodi2.sh | tee /tmp/InstallKodi.log" > /tmp/InstallKodi1.sh
#chmod 777 /tmp/InstallKodi1.sh

echo "Starting the terminal and continuing on HDMI out"
/usr/local/DFBTerm/bin/dfbterm --dfb:no-cursor,no-linux-input-grab,init-layer=0,layer-buffer-mode=triple,layer-bg-color=00000000,primary-only -c \"/tmp/InstallKodi2.sh\"

# Feel free to experiment with the --dfb: settings. The original RMA settings were:
#
# /usr/local/DFBTerm/bin/dfbterm --dfb:no-cursor,init-layer=0,layer-format=ARGB,layer-buffer-mode=triple,layer-bg-color=00000000,primary-only --fontsize=23 --position=35,20 --size=60x18  -c \"/data/hack/misc/shell.sh\"
#
# Added the "no-linux-input-grab" to force the recognition of the Boxee remote
#
# All settings can be found at: http://directfb.org/docs/directfbrc.5.html (offline)
# http://www.directfb.org/wiki/index.php/Configuring_DirectFB (offline)
# http://manpages.ubuntu.com/manpages/hardy/man5/directfbrc.5.html
