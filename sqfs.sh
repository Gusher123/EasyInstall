#!/bin/sh

# To run:
# curl -L https://raw.githubusercontent.com/Gusher123/EasyInstall/master/sqfs.sh | sh

# Last update: URL's Changed

version="2.2 d.d. 03-12-2017"
server="http://boxee-kodi.leechburgltc.com"
server2="https://raw.githubusercontent.com/Gusher123/EasyInstall/master"
server3="http://dl.boxeed.in"
server4="http://www.busybox.net"
server5="https://github.com"
mount_dir="/media/BOXEE"
label="BOXEE"

unmount()
{
mount | grep -q $1
if [ $? == 0 ]
then
	umount $1 | tee -a /tmp/sqfs.log
else
	echo -e -n "not mounted... " | tee -a /tmp/sqfs.log
fi
}

latest()
{
if [ ! -f /tmp/releases.quasar1 ] ; then 
#	curl -L -s $server5/quasar1/boxeebox-xbmc/releases -o /tmp/releases.quasar1.html
#	cat /tmp/releases.quasar1.html | grep release-downloads -A 5 | grep href | grep releases | awk '{print $2}' | cut -d '"' -f 2 | cut -d '/' -f 7 | cut -d '.' -f 1-2 >/tmp/releases.quasar1
	echo KODI_14.2-Git-2017-11-12-a103c6f-hybrid>/tmp/releases.quasar1
fi
if [ ! -f /tmp/releases.orizzle ] ; then 
	curl -L -s $server/releases.php | sort -t : -k 3 -r | cut -d ":" -f 2 >/tmp/releases.orizzle
fi
if [ ! -f /tmp/releases.git ] ; then 
	curl -L -s $server2/releases.git -o /tmp/releases.git
fi

latest_quasar1=`cat /tmp/releases.quasar1 | head -n1 | awk '{print $1}'`
latest_orizzle=`cat /tmp/releases.orizzle | head -n1 | awk '{print $1}'`

FILE=/tmp/releases.quasar1
while read line
do
	cat /tmp/releases.git | cut -d ":" -f 2 | grep -q $line
	if [ ! $? = 0 ]
	then
	#	echo "Dropbox list for making sqfs files yourself is not up to date"
	#	The format for /tmp/build.git is: /$path/$filename.$extention:$friendlyname:$builddate:$buildcategory
		url=`cat /tmp/releases.quasar1.html | grep release-downloads -A 5 | grep href | grep releases | awk '{print $2}' | cut -d '"' -f 2 | grep $line`
		friendlyname=`cat /tmp/releases.quasar1.html | grep release-downloads -A 5 | grep href | grep releases | awk '{print $2}' | cut -d '"' -f 2 | cut -d '/' -f 7 | grep $line`
		builddate=`echo $line | cut -d '-' -f 3-5`
		buildcategory=`echo $line | cut -d '-' -f 7`
		echo $url:$friendlyname:$builddate:$buildcategory >>/tmp/releases.git1
	fi
done < $FILE
cat /tmp/releases.git >>/tmp/releases.git1
mv /tmp/releases.git1 /tmp/releases.git

if [ -f /media/BOXEE/xbmc.sqfs ] && [ -f /media/BOXEE/addons.tar.bz2 ] && [ -f /media/BOXEE/build.md5 ]
then
	latest_usb=`cat /media/BOXEE/build.md5 | grep builddesc | awk '{print$3}'`
else
	latest_usb="NONE"
fi

cat /tmp/releases.orizzle | grep -q $latest_quasar1
if [ ! $? = 0 ] && [ ! $latest_quasar1 == $latest_usb ]
#if [ ! $? = 0 ]
then
	dialog --clear --backtitle "Newer version on git" --title " Make sqfs image yourself? " --yes-label " Make sqfs image yourself " --no-label " Use a precompiled " --yesno "\nThere is a new Kodi version available on git that is not yet available as a precompiled image.\n\nGit:  "$latest_quasar1"\nSite: "$latest_orizzle"\n\nDo you want to use this newer version and compile the sqfs image? You only need and empty USB drive to do this.\n" 14 70
	if [ ! $? -eq 0 ]
	then
		exit
	else
		main
	fi
else
	info
fi
}

info()
{
	dialog --clear --backtitle "Choose source" --title " Make sqfs image yourself? " --yes-label " Use precompiled " --no-label " Make sqfs image yourself " --yesno "\nDo you want to use one of the 7 precompiled Kodi/XBMC builds by Orizzle or build your own sqfs image directly from one of the 20 different Kodi/XBMC releases ever released by Quasar1?\n\nBuilding your own image will take about 10 minutes and you need and empty USB drive to do this.\n\n" 14 70
	if [ $? -eq 0 ]
	then
		exit
	else
		main
	fi
}

makesqfs()
{
	if [ -f /data/hack/init.d/99xbmc_launch.sh ] ; then mv /data/hack/init.d/99xbmc_launch.sh /data/hack/ ; fi
	clear
	echo "Making sqfs using "$friendlyname" build by quasar1" | tee /tmp/sqfs.log
	echo "Script version: $version" >>/tmp/sqfs.log
	date >>/tmp/sqfs.log
	device=`cat /proc/partitions | grep sd | head -n1 | awk '{print $4}'`
	nPartition=`fdisk -l /dev/$device | grep $device | awk END'{print $1}' | cut -c 9`
	echo "Step 1/10: removing all $nPartition partition(s) on /dev/$device" | tee -a /tmp/sqfs.log
	while true; do
		nPartition=`fdisk -l /dev/$device | grep $device | awk END'{print $1}' | cut -c 9`
		mount | grep /dev/sd >>/tmp/sqfs.log
		[ -z $nPartition ] && break
		echo -e -n "- unmounting /dev/$device$nPartition partition..." | tee -a /tmp/sqfs.log
		unmount "/dev/$device$nPartition"
		echo -e -n " done!\n" | tee -a /tmp/sqfs.log
		sleep 1
		if [ $nPartition == 1 ]; then
			echo -e -n "- removing /dev/$device$nPartition partition..." | tee -a /tmp/sqfs.log
			echo -e "d\nw\n" | fdisk /dev/$device >>/tmp/sqfs.log
			echo -e -n " done!\n" | tee -a /tmp/sqfs.log
		else
			echo -e -n "- removing /dev/$device$nPartition partition..." | tee -a /tmp/sqfs.log
			echo -e "d\n$nPartition\nw\n" | fdisk /dev/$device >>/tmp/sqfs.log
			echo -e -n " done!\n" | tee -a /tmp/sqfs.log
		fi
	done
	sleep 1
	echo -e -n "Step 2/10: creating new partition on /dev/$device..." | tee -a /tmp/sqfs.log
	echo -e "n\np\n1\n\n\nw\n" | fdisk /dev/$device >>/tmp/sqfs.log
	sleep 2
	cat /proc/partitions | grep -q "$device"1
	if [ $? != 0 ]
	then
		echo -e -n "Failed to create partition. Exiting.\n" | tee -a /tmp/sqfs.log
		if [ -f /data/hack/99xbmc_launch.sh ] ; then mv /data/hack/99xbmc_launch.sh /data/hack/init.d/ ; fi
		sleep 10
		exit
	else
		echo -e -n " /dev/"$device"1 created\n" | tee -a /tmp/sqfs.log
	fi
	echo -e -n "- syncing..." | tee -a /tmp/sqfs.log
	sync;sync;sync
	sleep 5
	echo -e -n " done!\n" | tee -a /tmp/sqfs.log
	partition=`mount | grep /dev/sd | awk '{print $1}'`
	if [ $partition ]
	then
		echo -e -n "- unmounting $partition partition..." | tee -a /tmp/sqfs.log
		mount | grep /dev/sd >>/tmp/sqfs.log
		unmount $partition
		echo -e -n " done!\n" | tee -a /tmp/sqfs.log
	fi
	sleep 5
	partition="/dev/`cat /proc/partitions | grep sd | head -n1 | awk '{print $4}'`1"
	echo -n -e "Step 3/10: formatting $partition partition\n" | tee -a /tmp/sqfs.log
#	echo -e "\n" >>/tmp/sqfs.log
	cat /proc/partitions | grep sd >>/tmp/sqfs.log
#	mkfs.ext3 -L $label $partition >>/tmp/sqfs.log
	/tmp/busybox/mkfs.vfat -n $label $partition >>/tmp/sqfs.log
	sleep 5
	echo "Step 4/10: mounting $partition partition on $mount_dir"/ | tee -a /tmp/sqfs.log
	if [ ! -d $mount_dir/ ] ; then mkdir $mount_dir/ ; echo "mkdir $mount_dir/" >>/tmp/sqfs.log ; fi
	mount $partition $mount_dir/ | tee -a /tmp/sqfs.log
	sleep 5
	cd $mount_dir/
	echo "mkdir $mount_dir/bin/" >>/tmp/sqfs.log
	mkdir $mount_dir/bin/ | tee -a /tmp/sqfs.log
	echo "Step 5/10: installing mksquashfs, unsquashfs, unrar en p7zip" | tee -a /tmp/sqfs.log
	curl -L -# $server2/mksquashfs -o $mount_dir/bin/mksquashfs
	chmod +rwx $mount_dir/bin/mksquashfs
	curl -L -# $server2/unsquashfs -o $mount_dir/bin/unsquashfs
	chmod +rwx $mount_dir/bin/unsquashfs
	curl -L -# $server2/unrar -o $mount_dir/bin/unrar
	chmod +rwx $mount_dir/bin/unrar
	curl -L -# http://downloads.sourceforge.net/project/p7zip/p7zip/9.20.1/p7zip_9.20.1_x86_linux_bin.tar.bz2 -o $mount_dir/p7zip_9.20.1_x86_linux_bin.tar.bz2
	tar -xvjf $mount_dir/p7zip_9.20.1_x86_linux_bin.tar.bz2 -C $mount_dir/ >/dev/null
	cp -r $mount_dir/p7zip_9.20.1/bin/* $mount_dir/bin/
	echo "Step 6/10: downloading "$friendlyname" from github" | tee -a /tmp/sqfs.log
	curl -L -# $server5/$url -o $mount_dir/$filename.$extention
	echo "Step 7/10: extracting archive (this will take a few minutes)" | tee -a /tmp/sqfs.log
	echo "extention = $extention" >>/tmp/sqfs.log
	if [ $extention = "rar" ]
	then
		echo "$mount_dir/bin/unrar x -inul $mount_dir/$filename.$extention $mount_dir/" >>/tmp/sqfs.log
		$mount_dir/bin/unrar x -inul $mount_dir/$filename.$extention $mount_dir/ | tee -a /tmp/sqfs.log 
	elif [ $extention = "7z" ]
	then
		echo "$mount_dir/bin/7za x -o$mount_dir/ $mount_dir/$filename.$extention >/dev/null" >>/tmp/sqfs.log
		$mount_dir/bin/7za x -o$mount_dir/ $mount_dir/$filename.$extention >/dev/null | tee -a /tmp/sqfs.log 
	else
		echo unknow format | tee -a /tmp/sqfs.log
		if [ -f /data/hack/99xbmc_launch.sh ] ; then mv /data/hack/99xbmc_launch.sh /data/hack/init.d/ ; fi
		sleep 10
		exit
	fi
	if [ -d $mount_dir/$dirname/addons/ ] ; then dirname=$filename
	elif [ -d $mount_dir/$dirname/xbmc/addons/ ] ; then dirname=$filename/xbmc
	elif [ -d $mount_dir/$dirname/kodi/addons/ ] ; then dirname=$filename/kodi
	else
		echo "Can't find addon directory. Exiting"  | tee -a /tmp/sqfs.log
		if [ -f /data/hack/99xbmc_launch.sh ] ; then mv /data/hack/99xbmc_launch.sh /data/hack/init.d/ ; fi
		sleep 10
		exit
	fi
	echo "addons in $mount_dir/$dirname/addons/" >>/tmp/sqfs.log
	cd $mount_dir/$dirname/addons/
	sleep 1
	echo "Step 8/10: making addons.tar.bz2 (this will take a few minutes)" | tee -a /tmp/sqfs.log
	tar -cjf $mount_dir/addons.tar.bz2 * | tee -a /tmp/sqfs.log 
	cd $mount_dir/
	rm -rf $mount_dir/$dirname/addons/*
#	ln -s /data/hack/xbmc/addons $mount_dir/$dirname
#	rm -R $mount_dir/$dirname/portable_data/
#	ln -s /download/xbmc/portable_data $mount_dir/$dirname
	chmod +x $mount_dir/$dirname/*.bin
	echo "Step 9/10: making sqfs (this will take a few minutes)" | tee -a /tmp/sqfs.log
	$mount_dir/bin/mksquashfs $mount_dir/$dirname/ $mount_dir/xbmc.sqfs -all-root -noappend
	$mount_dir/bin/unsquashfs -stat /media/BOXEE/xbmc.sqfs >>/tmp/sqfs.log
	echo "Step 10/10: generarting build.md5" | tee -a /tmp/sqfs.log
	echo "# buildname Install_Kodi_from_usb_stick" > $mount_dir/build.md5
	echo "# builddesc $filename" >> $mount_dir/build.md5
	echo "# buildtype from_usb" >> $mount_dir/build.md5
	echo -n "# buildtime " >> $mount_dir/build.md5
	date +%s >> $mount_dir/build.md5
	md5sum $mount_dir/xbmc.sqfs $mount_dir/addons.tar.bz2 | tee -a /tmp/sqfs.log >> $mount_dir/build.md5
#	rm -rf $mount_dir/$filename
#	rm -rf $mount_dir/bin
#	rm -rf $mount_dir/p7zip_9.20.1
#	rm $mount_dir/$filename.$extention
#	rm $mount_dir/p7zip_9.20.1_x86_linux_bin.tar.bz2
	chmod 755 $mount_dir/xbmc.sqfs $mount_dir/addons.tar.bz2 $mount_dir/build.md5
	echo "Done!" | tee -a /tmp/sqfs.log
	cp /tmp/sqfs.log $mount_dir/
	sleep 5
}

main()
{
	if [ ! -f /tmp/releases.git ] ; then 
		curl -L -s $server2/releases.git -o /tmp/releases.git
	fi

	options=`awk -F":" 'BEGIN { n=1 }; { printf "\"" n++ "\" \"[" $4 "] " $3 " " substr($2,0,47) "\" on " }' /tmp/releases.git`
	cmd="dialog --clear --backtitle \"Release Selection\" --radiolist \"The following 20 Kodi/XBMC releases by quasar1 are available from github to build your own sqfs.\n\nSelect a release to install with the arrow keys and spacebar.\nPress ENTER to confirm your selection.\" 15 80 15 $options 2>/tmp/release.git"
	echo NONE>/tmp/release.git
	eval $cmd
	ret=$?
	if [ $ret -eq 0 ]
	then	
	#	The format for /tmp/build.git is: /$path/$filename.$extention:$friendlyname:$builddate:$buildcategory
 		echo `cat /tmp/releases.git | head -n\`cat /tmp/release.git\` | tail -n1` >/tmp/build.git
		url=`cat /tmp/build.git | cut -d: -f1`
		path=`echo $url | cut -d '/' -f 1-6`
		filename=`echo $url | cut -d '/' -f 7 | cut -d '.' -f 1-2`
		extention=`echo $url | cut -d '/' -f 7 | cut -d '.' -f 3`
		friendlyname=`cat /tmp/build.git | cut -d: -f2`
		builddate=`cat /tmp/build.git | cut -d: -f3`
		buildcategory=`cat /tmp/build.git | cut -d: -f4`
		dirname=$filename

		mount | grep -q /dev/sd
		pluggedin=$?
		if [ $pluggedin -eq 0 ]
		then
			partition=`mount | grep /dev/sd | awk '{print $1}'`
			dialog --clear --backtitle "USB drive found" --title " Do you want to continue " --yesno "\nUSB drive found on "$partition".\n\n\nTHE USB DRIVE WILL BE FORMATTED AND ALL CONTENTS ON YOUR USB DRIVE WILL BE LOST!\n\n\nDo you want to continue?" 14 70
			if [ ! $? -eq 0 ]
			then
				exit
			fi
		else
			dialog --clear --backtitle "Compiling sqfs image" --title " Insert empty USB drive " --yesno "\nInsert a formatted USB drive with label '"$label"' into your boxee.\n\n\nTHE USB DRIVE WILL BE FORMATTED AND ALL CONTENTS ON YOUR USB DRIVE WILL BE LOST!\n\n\nDo you want to proceed?" 14 70
			if [ $? -eq 0 ]
			then
				echo "Plug in your empty USB drive now..."
				while true; do
					mount | grep -q /dev/sd && break
				done
			else
				exit
			fi
		fi

		partition=`mount | grep /dev/sd | awk '{print $1}'`
		makesqfs
		local_date=`stat $mount_dir/xbmc.sqfs | grep Modify | awk '{print $2}'`
		echo Install_Kodi_from_usb_stick:$filename:$local_date:from_usb >/tmp/releases
	fi
}

###################################################################################################

case $1 in
	"checklatest")
	latest
	;;
	"info")
	info
	main
	;;
	*)
	main
	;;
esac
