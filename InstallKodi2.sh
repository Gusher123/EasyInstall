#!/bin/sh

# To run:
# curl -L https://github.com/Gusher123/EasyInstall/raw/master/InstallKodi2.sh | sh

# Version 2.1 d.d. 14-09-2017

# Last update: URL's Changed
# Substitute wget for curl in Orizzle's script, because wget stalls when downloading xbmc/kodi from his site
# Moved the checking server offline up and added a timeout of 25 seconds.
# Workaroud for SSL curl problem with www.archlinux.org website, downloading from busybox.net instead
# Sorting releases by date
# Updated busybox script to download latest available version (1.24.1)
# Remove /data/hack/bin/cp because it is not backwards compatible with original /opt/local/bin/ps
# Read/write buildinfo for 'Install_Kodi_from_usb_stick' to/from build.md5 file
# Updated script for making a sqfs image on a USB drive; added logging, rewrote (un)partitioning part of the script
# Check for newer versions on github and if there is one, offer to run makesqfs script
# Check for locally made sqfs files on USB drive and if available, add to the list of available installations
# Check for new version of busybox and only suggest to install when new version is available
# Updated busybox to download latest version from busybox website and install softlinks to /data/hack/bin/
# Use /opt/local/bin/ps specifically for compatability when installing busybox
# Added: Also killling Kodi.bin in installer.sh script
# Added option to use backup server
# Added a patch to correct md5 typo in boxeehack_update.py
# Updated $server to http://boxee-kodi.leechburgltc.com/ and updated MD5 checksum
# Added re-read boxee_hacks_version after updating Boxee+Hacks from an older version
# Replaced reboot with poweroff command to prevent Boxeebox from hanging when rebooting
# Added the option to start a shell with no password at the end
# Added a patch to installhacks() so that the script does not delete itself
# Moved temporary telnetd and ftpd to initial installer
# Added dropping you a shell when cancelling or exiting without installing Boxee+Hacks
# Added MD5 checks to Hacks+install script and XBMC/Kodi install script to track changes
# Added pauses after installation of BoxeeHacks and Extra's

# TODO: Check for Hacks version greater then available
# TODO: Integrate remove Kodi from /tmp/releases and Add Install_Kodi_from_usb

# Empty /download in one line:
# for f in /download/*; do if [ ${f} != "/download/xbmc" ]; then if ! [ -h "${f}" ]; then echo $f; rm -fr "${f}" ; fi ; fi; done

###################################################################################################################

server="http://boxee-kodi.leechburgltc.com"
server2="https://github.com/Gusher123/EasyInstall/raw/master"
server3="http://dl.boxeed.in"
server4="https://www.archlinux.org/packages/community/i686/busybox"
server4a="http://mirror.rit.edu/archlinux/community/os/i686/"
server4b="https://git.archlinux.org/svntogit/community.git/log/?h=packages/busybox"
server4c="https://busybox.net/downloads/binaries/1.26.2-i686/busybox"
server5="https://github.com"

# Change logo back to green
dtool 6 1 0 0 
dtool 6 2 0 50

# We cannot use dialog from /data/hack/bin because it might get wiped when reinstalling Boxee+Hacks
if [ ! -f /tmp/dialog/dialog ]
then
	mkdir -p /tmp/dialog
	curl -L -s $server2/backup/kodi/dialog -o /tmp/dialog/dialog 
	chmod +x /tmp/dialog/dialog
fi

if [ ! -f /tmp/shell_tmp.sh ]
then
	curl -L -s $server2/shell_tmp.sh -o /tmp/shell_tmp.sh
	chmod 777 /tmp/shell_tmp.sh
fi

THEPATH='/tmp/dialog:/data/hack/bin:/opt/local/bin:/usr/local/bin:/usr/bin:/bin:/opt/local/sbin:/usr/local/sbin:/usr/sbin:/sbin:/scripts'

for f in /data/plugins/*; do
	if [ -d ${f}/bin ]; then
		THEPATH="${f}/bin:${THEPATH}"
	fi
done

export PATH="${THEPATH}"
export LD_LIBRARY_PATH='.:/tmp/lib:/data/hack/lib:/opt/local/lib:/usr/local/lib:/usr/lib:/lib:/lib/gstreamer-0.10:/opt/local/lib/qt'
export HOME='/data/hack'
export ENV='/data/etc/.profile'
export TERM=vt102
export TERMINFO='/share/terminfo/'
#export DIALOGRC='/tmp/.dialogrc'

serial=`/opt/local/bin/get_platform_params 2`
my_ip=`ifconfig | grep "inet addr" | grep -v "127.0.0.1" | awk '{print $2 }' | cut -f2 -d:`

###################################################################################################################

#echo -n Checking $server/installer.sh...
#http_code=$(curl -L -s -o /tmp/out.html -w '%{http_code}' $server/installer.sh --connect-timeout 25;)
#if [[ $http_code -ne 200 ]]
#then
#	dialog --clear --backtitle "Server offline" --title " Kodi server offline " --yes-label " Use Backup server " --no-label " Use Kodi server " --yesno "\nIt seems that the Kodi server ($server) is offline. (Code: $http_code)\n\nPlease report to http://boxeed.in/forums/viewtopic.php?f=5&t=1216\n\nDo you want to use my backup of the Kodi server instead?\n\nThe backup server might not be up to date." 13 70
#	if [ $? -eq 0 ]
#	then
#		server=$server2"/backup/kodi"
#		kodi_backup=1
#	else
#		kodi_backup=0
#	fi
#	echo ""
#else
#	echo " Online."
#fi
#
#echo -n Checking $server3/install.sh...
#http_code=$(curl -L -s -o /tmp/out.html -w '%{http_code}' $server3/install.sh --connect-timeout 25;)
#if [[ $http_code -ne 200 ]]
#then
#	dialog --clear --backtitle "Server offline" --title " Boxee+Hacks server offline " --yes-label " Use Backup server " --no-label " Use Boxee+Hacks server " --yesno "\nIt seems that the Boxee+Hacks server ($server3) is offline. (Code: $http_code)\n\nPlease report to http://boxeed.in/forums/viewtopic.php?f=5&t=1104\n\nDo you want to use my backup of the Boxee+Hacks server instead?\n\nThe backup server might not be up to date." 13 70
#	if [ $? -eq 0 ]
#	then
#		server3=$server2"/backup/hacks"
#		hacks_backup=1
#	else
#		hacks_backup=0
#	fi
#	echo ""
#else
#	echo " Online."
#fi
#
#if [ "$serial" = "QL034C1006667" ]
#then
#	dialog --clear --title " Hello Gusher " --yes-label " Use Dropbox " --no-label " Use Standard " --yesno "\nHello Gusher\n\nDo you want to use the Kodi server or your Dropbox backup?" 10 70
#	if [ $? -eq 0 ]
#	then
#		server=$server2"/backup/kodi"
#		server3=$server2"/backup/hacks"
#		dropbox=1
#	else
#		dropbox=0
#	fi
#fi

###################################################################################################################

boxee_hacks_version_string=`cat /data/hack/version 2>/dev/null`
boxee_hacks_version=`echo $boxee_hacks_version_string 2>/dev/null | sed -e 's/\.//g' -e :a -e 's/^.\{1,2\}$/&0/;ta'`
boxeed_in_version_string=`curl -L -s $server3/version 2>/dev/null`
boxeed_in_version=`echo $boxeed_in_version_string 2>/dev/null | sed -e 's/\.//g' -e :a -e 's/^.\{1,2\}$/&0/;ta'`

curl -L -s $server5/quasar1/boxeebox-xbmc/releases -o /tmp/releases.quasar1.html
cat /tmp/releases.quasar1.html | grep release-downloads -A 5 | grep href | awk '{print $2}' | cut -d '"' -f 2 | cut -d '/' -f 7 | cut -d '.' -f 1-2 >/tmp/releases.quasar1

curl -L -s $server/releases.php -o /tmp/releases.php
if [ -f /media/BOXEE/xbmc.sqfs ] && [ -f /media/BOXEE/addons.tar.bz2 ] && [ -f /media/BOXEE/build.md5 ]
then
	echo "SQFS image files found on usb drive. Adding it to the menu"
	buildname=`cat /media/BOXEE/build.md5 | grep buildname | awk '{print$3}'`
	builddesc=`cat /media/BOXEE/build.md5 | grep builddesc | awk '{print$3}'`
	buildtype=`cat /media/BOXEE/build.md5 | grep buildtype | awk '{print$3}'`
#	buildtime=`cat /media/BOXEE/build.md5 | grep buildtime | awk '{print$3}'`
	buildtime=`date -r /media/BOXEE/xbmc.sqfs +"%Y-%m-%d"`
	echo $buildname:$builddesc:$buildtime:$buildtype >/tmp/releases.usb
	cat /tmp/releases.php >>/tmp/releases.usb
	cat /tmp/releases.usb | sort -t : -k 3 -r >/tmp/releases
else
	cat /tmp/releases.php | sort -t : -k 3 -r >/tmp/releases
fi

cat /tmp/releases | cut -d ":" -f 2 >/tmp/releases.orizzle

kodi_latest_version=`cat /tmp/releases.quasar1 | head -n1  | awk '{print $1}'`
xbmc_latest_version=`cat /tmp/releases.orizzle | grep -i xbmc | head -n1 | awk '{ print $1 }'`

###################################################################################################################

startshell()
{
	# Run shell without a password if you don't reboot
	/opt/local/bin/ps -A -F | grep -q telnetd
	if [ $? -eq 0 ];
	then
		echo "telnetd running at $my_ip port 2323"
	fi
	/opt/local/bin/ps -A -F | grep -q ftpd
	if [ $? -eq 0 ];
	then
		echo "ftpd running at $my_ip port 21"
	fi
	echo ""
	echo "Starting a shell. Type <poweroff> when you are finished."
	echo ""
	sh $1
	exit
}

installhacks()
{
	clear
	echo -n "Downloading Cigamit's Boxee+Hack install script... "
	curl -L -s $server3/install.sh -o /download/install.sh
	md5_1=$(md5sum /download/install.sh | awk '{print $1}')
	md5_2=afda43b02192a73864b278ab600eecfc
	if [ "$md5_1" != "$md5_2" ]
	then
		dialog --clear --backtitle " MD5 checksum error " --title " MD5 checksum error " --no-label " Continue " --yes-label " Exit " --yesno "\nBoxee+Hacks installer MD5 checksum is different then expected.\nSource: $server3/install.sh\nMD5 found:    $md5_1\nMD5 expected: $md5_2\n\nTry again and if the error persists contact me through http://boxeed.in/forums/viewtopic.php?f=5&t=1216" 13 70
		if [ $? -eq 0 ]
		then
			startshell /tmp/shell_tmp.sh
		fi
	else
		echo MD5 checksum OK
	fi
#	if [ "$dropbox" -eq 1 ] || [ "$hacks_backup" -eq 1 ]
#	then
#		echo Patch script to use Dropbox
#		sed -i 's/http:\/\/dl.boxeed.in/https:\/\/dl.dropboxusercontent.com\/u\/22813771\/backup\/hacks/' /download/install.sh
#	fi
	echo Patch script not to delete itself
	sed -i 's/for f in \/download\/\*; do/for f in \/download\/\*; do\nbreak/' /download/install.sh
#	sed -i 's/\[ \${f} != "\/download\/xbmc" \]/[ \${f} != "\/download\/xbmc" \] \&\& [ \${f} != "\/download\/install.sh" \]/' /download/install.sh
#	sed -i 's/rm -fr/#rm -fr/' /download/install.sh
	echo Patch script to output to both file and screen
	sed -i 's/>>/| tee -a/' /download/install.sh
	sed -i 's/>.\$/| tee \$/' /download/install.sh
	echo "Patch script to make it's output to screen more readable"
	sed -i 's/unzip boxeehack.zip/unzip boxeehack.zip >\/dev\/null/' /download/install.sh
	sed -i 's/curl/curl -#/' /download/install.sh
	sed -i 's/echo "\$BASEDIR\/hack"/echo "Use \$BASEDIR\/hack as temporary working directory"/' /download/install.sh
	sed -i 's/rm \/download\/boxeehack.zip/rm -f \/download\/boxeehack.zip/' /download/install.sh
	sed -i 's/umount -f \/opt\/boxee\/skin$/umount -f \/opt\/boxee\/skin 2>\/dev\/null/' /download/install.sh
	sed -i 's/umount -f \/opt\/boxee\/media\/boxee_screen_saver/umount -f \/opt\/boxee\/media\/boxee_screen_saver 2>\/dev\/null/' /download/install.sh
	sed -i 's/umount -f \/opt\/boxee\/skin\/boxee\/720p/umount -f \/opt\/boxee\/skin\/boxee\/720p 2>\/dev\/null/' /download/install.sh
	sed -i 's/umount -f \/opt\/boxee\/visualisations\/projectM/umount -f \/opt\/boxee\/visualisations\/projectM 2>\/dev\/null/' /download/install.sh
	echo Patch script not to reboot at finsh
	sed -i 's/rm \/download\/install.sh; reboot//' /download/install.sh
	echo Patch script to save install.log to /data/hack/misc/ 
	sed -i 's/Rebooting/Saving install.log to \/data\/hack\/misc\/ /' /download/install.sh
	sed -i 's/\# reboot the box to activate the hack/mv \/download\/install.log \/data\/hack\/misc\//' /download/install.sh
	echo "Starting patched Boxee+Hacks install script"
	sh /download/install.sh
	echo Patching boxeehack_update.py to correct md5 typo
	sed -i 's/tm = common.file_get_contents("\/download\/boxeehack.md5")/tm = common.file_get_contents("\/download\/boxeehack.md52")/' /data/hack/boxee/skin/boxee/720p/scripts/boxeehack_update.py
	echo "Saving patched install.sh script in /data/hack/misc/"
	cp /download/install.sh /data/hack/misc/
	echo "Saving uninstall script to /data/hack/misc/"
	curl -L -s $server2/uninstall_hacks.sh -o /data/hack/misc/uninstall_hacks.sh
	chmod +x /data/hack/misc/uninstall_hacks.sh
	boxee_hacks_version_string=`cat /data/hack/version 2>/dev/null`
	boxee_hacks_version=`echo $boxee_hacks_version_string 2>/dev/null | sed -e 's/\.//g' -e :a -e 's/^.\{1,2\}$/&0/;ta'`
	echo "Done!"
	Sleep 2
}

###################################################################################################################

dialog --clear --title " Warning " --yesno "\nThis script allows you to install Boxee+Hacks version $boxeed_in_version_string and Kodi/XBMC up to version $kodi_latest_version. \n\nUse your Boxee's remote controller to select <Yes> or <No> and confirm with the <Middle button> or <Enter>. Use <Spacebar> to select/deselect options.\n\nFor diagnostics telnetd has been opened at $my_ip port 2323 and ftpd at $my_ip port 21.\n\nThis script is provided without a warranty of any kind. Make sure you know how to perform a factory reset before proceeding.\n\nDo you want to continue?" 20 70
if [ $? -gt 0 ]
then
	dialog --clear --title " Exiting " --msgbox "\nInstallation cancelled!" 7 70
	startshell /tmp/shell_tmp.sh
fi


if [ ! -f /data/hack/version ]
then
	dialog --clear --title " Install Boxee+Hacks " --yesno "\nThis script must be run on a Boxee with Boxee+Hacks installed.\n\nDo you want to install the latest version of Boxee+Hack?" 9 70
	if [ $? -eq 0 ]
	then
		installhacks
	else
		dialog --clear --title " Exiting " --msgbox "\nYou cannot install XBMC/Kodi without installing Boxee+Hacks.\n\nExiting..." 9 70
		startshell /tmp/shell_tmp.sh
	fi
else
	if [ $boxee_hacks_version -eq $boxeed_in_version ]
	then
		dialog --clear --title " Latest version present " --yes-label " Ok " --no-label " Reinstall " --yesno "\nLatest Boxee+Hack version $boxee_hacks_version_string present.\n\nSelect <Ok> to continue or <Reinstall> to reinstall Boxee+Hacks." 9 70
		if [ ! $? -eq 0 ]
		then
			installhacks
		fi
	else
		dialog --clear --title " Update Boxee+Hacks " --yesno "\nBoxee+Hacks version installed: $boxee_hacks_version_string\nLatest Boxee+Hacks available:  $boxeed_in_version_string\n\nYou need Boxee+Hacks 1.6.0 to run $kodi_latest_version or 1.5.5 to run $xbmc_latest_version or earlier.\n\nDo you want to install the latest version of Boxee+Hack?" 13 70
		if [ $? -eq 0 ]
		then
			installhacks
		else
			dialog --clear --title " Keeping Boxee+Hacks " --msgbox "\nKeeping Boxee+Hacks version $boxee_hacks_version_string. You cannot install Kodi.\n\nIf you run into any problems installing XBMC or want to install Kodi, run the installer again and choose to update Boxee+Hacks." 11 70
		fi
	fi
fi

rm -f /tmp/extras

clear;echo -n "Checking for installed extra's... "
busybox1=`busybox | head -n1 | awk '{print $2'} | cut -c2-7`
#busybox2=`curl -L -s $server4/ | grep version | awk '{print $3}' | cut -d '"' -f2 | cut -c1-6`
busybox3=`curl -L -s $server4b | grep upgpkg | sed -n 's/.*busybox.//p' | sed 's/<\/a><span.*//p' | head -n1`
busybox2=`echo $busybox3 | cut -c1-6`
echo "Done"

if [ "$busybox1" != "$busybox2" ]
then
	busyboxyn=on
	defaultno=""
else
	busyboxyn=off
	defaultno="--defaultno"
fi

dialog --clear --backtitle "Select extra's" --title " Extra's " $defaultno --cancel-label " Do not install " --ok-label " Install extra's " --checklist "\nSelect which extra's you want to install using the arrow keys and spacebar.\n " 13 60 3 "Install DFBTerminal" "" off "Install thttpd server hack" "" off "Update busybox "$busybox1" to latest version ("$busybox2")" "" $busyboxyn 2>/tmp/extras

extra_DFBT=`cat /tmp/extras | grep -c DFBTerminal`
extra_thttpd=`cat /tmp/extras | grep -c thttpd`
extra_busybox=`cat /tmp/extras | grep -c busybox`

clear

if [ $extra_DFBT -eq 1 ]
then
	echo "Installing DFBTerminal..."
	if [ -f /data/hack/init.d/24DFBTerm.sh ]
	then
		umount /data/hack/local_mnt
	fi
	curl -L -s $server2/InstallDFBTerm.sh -o /tmp/InstallDFBTerm.sh && sh /tmp/InstallDFBTerm.sh nostart
#	echo -n "Done. Press any key to continue...";read a;clear
fi

if [ $extra_thttpd -eq 1 ]
then
	echo "Installing thttpd server hack..."
	if [ -d /data/hack/www ]
	then
		umount /data/hack/www/thttpd.conf
	fi
	curl -L -s $server2/thttpd_hack_install.sh -o /tmp/thttpd_hack_install.sh && sh /tmp/thttpd_hack_install.sh
#	echo -n "Done. Press any key to continue...";read a;clear
fi

if [ $extra_busybox -eq 1 ]
then
	echo "Updating busybox to latest version"
#	curl -L -s $server4/download/ -o /tmp/busybox.pkg.tar.xz

#	curl -L -s $server4a/busybox-$busybox3-i686.pkg.tar.xz -o /tmp/busybox.pkg.tar.xz
#	/data/hack/bin/busybox tar xJf /tmp/busybox.pkg.tar.xz -C /tmp/

	mkdir -p /tmp/usr/bin/
	curl -L -s $server4c -o /tmp/usr/bin/busybox
	chmod 777 /tmp/usr/bin/busybox
	mv -f /tmp/usr/bin/busybox /data/hack/bin/busybox
	/data/hack/bin/busybox --install -s /data/hack/bin/
	rm /data/hack/bin/ps
#	echo -n "Done. Press any key to continue...";read a;clear
fi

clear
echo -n "Downloading Orizzle's Kodi/XBMC Automatic Installer script... "
curl -L -s $server/installer.sh -o /tmp/installer.sh
curl -L -s $server2/shell_no_password.sh -o /tmp/shell_no_password.sh
md5_1=$(md5sum /tmp/installer.sh | awk '{print $1}')
md5_2=e961ddf6385c85947eed535a34ae14eb
if [ "$md5_1" != "$md5_2" ]
then
	dialog --clear --title " MD5 checksum error " --no-label " Continue " --yes-label " Exit " --yesno "\nXBMC/Kodi installer MD5 checksum is different then expected.\nSource: $server/installer.sh\nMD5 found:    $md5_1\nMD5 expected: $md5_2\n\nTry again and if the error persists contact me through http://boxeed.in/forums/viewtopic.php?f=5&t=1216" 13 70
	if [ $? -eq 0 ]
	then
		startshell /tmp/shell_tmp.sh
	fi
#	dialog --clear --title " MD5 checksum error " --msgbox "\nXBMC/Kodi installer MD5 checksum is different then expected.\nSource: $server/installer.sh\nMD5 found:    $md5_1\nMD5 expected: $md5_2\n\nTry again and if the error persists contact me through http://boxeed.in/forums/viewtopic.php?f=5&t=1216\n\nExiting..." 15 70
#	startshell /tmp/shell_no_password.sh
else
	echo MD5 checksum OK
fi
echo Patch script to use curl in stead of wget
sed -i 's/#! \/bin\/sh/&\n\nwget()\n{\ncurl -# $3 -o $2\n}/g' /tmp/installer.sh
#if [ "$dropbox" -eq 1 ] || [ "$kodi_backup" -eq 1 ]
#then
#	echo Patch script to use Dropbox
#	sed -i 's/http:\/\/boxee-kodi.leechburgltc.com/https:\/\/dl.dropboxusercontent.com\/u\/22813771\/backup\/kodi/' /tmp/installer.sh
#fi
#echo "Patch script to add pauses before clearing the screen"
#sed -i 's/clear/echo -n "Done. Press any key to continue...";read a;clear/' /tmp/installer.sh
echo "Patch script to use graphical dialog boxes"
sed -i 's/--ascii-lines/--clear/' /tmp/installer.sh
echo "Patch script not to install Dropbear by default (installed by Boxee+Hacks)"
sed -i 's/on \"Reboot/off \"Reboot/' /tmp/installer.sh
echo "Patch script to add the option to 'Do not install' the features"
sed -i 's/--nocancel/--cancel-label " Do not intsall "/' /tmp/installer.sh
echo "Patch script to kill both xbmc.bin and kodi.bin"
sed -i '/killall xbmc.bin/a killall kodi.bin 2\>\/dev\/null' /tmp/installer.sh
if [ $boxee_hacks_version -lt $boxeed_in_version ]
then
	echo "Not running the latest version of Boxee+Hacks, removing Kodi from /tmp/releases"
	sed -i 's/-O \/tmp\/releases/-O -/' /tmp/installer.sh
	sed -i 's/releases.php/releases.php|grep -i -v kodi >\/tmp\/releases/' /tmp/installer.sh
else
	echo "Patch script to enable install from usb"
	sed -i 's/wget -O \/tmp\/releases/#wget -O \/tmp\/releases -/' /tmp/installer.sh
	sed -i 's/rm -f \/tmp\/releases/#rm -f \/tmp\/releases/' /tmp/installer.sh
	sed -i 's/wget -O \/tmp\/build.md5 $server\/$build\/build.md5/if [ $build == "Install_Kodi_from_usb_stick" ]\nthen\ncp \/media\/BOXEE\/build.md5 \/tmp\/build.md5\nelse\nwget -O \/tmp\/build.md5 $server\/$build\/build.md5\nfi/' /tmp/installer.sh
	sed -i 's/wget -O \/data\/hack\/xbmc\/xbmc.sqfs $server\/$build\/xbmc.sqfs/if [ $build == "Install_Kodi_from_usb_stick" ]\nthen\ncp \/media\/BOXEE\/xbmc.sqfs \/data\/hack\/xbmc\/xbmc.sqfs\nelse\nwget -O \/data\/hack\/xbmc\/xbmc.sqfs $server\/$build\/xbmc.sqfs\nfi/' /tmp/installer.sh
	sed -i 's/wget -O \/tmp\/addons.tar.bz2 $server\/$build\/addons.tar.bz2/if [ $build == "Install_Kodi_from_usb_stick" ]\nthen\ncp \/media\/BOXEE\/addons.tar.bz2 \/tmp\/addons.tar.bz2\nelse\nwget -O \/tmp\/addons.tar.bz2 $server\/$build\/addons.tar.bz2\nfi/' /tmp/installer.sh
	# Display different column
	sed -i 's/cut -d: -f2/cut -d: -f1/' /tmp/installer.sh
	echo "Patch script to delete current addons before installing ones from usb"
	sed -i 's/bar -n/if [ $build == "Install_Kodi_from_usb_stick" ]\nthen\nrm -rf \/data\/hack\/xbmc\/addons\/*\nfi\n\nbar -n/' /tmp/installer.sh
#	if [ -f /media/BOXEE/xbmc.sqfs ] && [ -f /media/BOXEE/addons.tar.bz2 ] && [ -f /media/BOXEE/build.md5 ]
#	then
#		echo "SQFS image files found on usb drive. Adding it to the menu"
#		buildname=`cat /media/BOXEE/build.md5 | grep buildname | awk '{print$3}'`
#		builddesc=`cat /media/BOXEE/build.md5 | grep builddesc | awk '{print$3}'`
#		buildtype=`cat /media/BOXEE/build.md5 | grep buildtype | awk '{print$3}'`
#		buildtime=`cat /media/BOXEE/build.md5 | grep buildtime | awk '{print$3}'`
#		echo $buildname:$builddesc:$buildtime:$buildtype >/tmp/releases.new
#		cat /tmp/releases >>/tmp/releases.new
#		mv /tmp/releases.new /tmp/releases
#	fi
	echo "Patch script to enable you to make your own SQFS image"
	curl -L -s $server2/sqfs.sh -o /tmp/sqfs.sh
	chmod +rwx /tmp/sqfs.sh
#	sed -i 's/--backtitle \\"Release Selection\\"/--backtitle \\"Release Selection\\" --ok-label \\"Use precompiled\\" --extra-button --extra-label \\"Make SQFS image\\"/' /tmp/installer.sh
	sed -i 's/options=/\/tmp\/sqfs.sh checklatest\n\noptions=/' /tmp/installer.sh
#	awk '/echo Installation cancelled!/{c++;if(c==3){sub("echo Installation cancelled!","if [ $ret -eq 3 ] ; then sh /tmp/sqfs.sh; fi");c=0}}1' /tmp/installer.sh >/tmp/installer.awk
#	mv /tmp/installer.awk /tmp/installer.sh
#	chmod +rwx /tmp/installer.sh
fi
echo "Patch script to replace existing reboot section with a dialog box"
sed -i 's/echo -n You must reboot to complete the installation./dialog --clear --title " Poweroff " --yes-label " Poweroff " --no-label " Start a shell "  --yesno "\nYou must restart your boxeebox to complete the installation." 7 70 ; if [ $? -eq 0 ] ; then poweroff ; else exit ; fi/' /tmp/installer.sh
echo "Saving patched script in /data/hack/misc/"
cp /tmp/installer.sh /data/hack/misc/
echo "Starting the patched XBMC/Kodi installer"
sh /tmp/installer.sh
startshell /tmp/shell_no_password.sh
exit