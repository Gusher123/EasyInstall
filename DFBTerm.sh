#!/bin/sh
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/DFBTerm/lib

if [ `ps -A | grep -i -c xbmc.bin` -eq 1 ] || [ `ps -A | grep -i -c kodi.bin` -eq 1 ]; then
	killall xbmc.bin
	killall kodi.bin
fi

if [ `ps -A | grep -i -c boxeehal` -eq 1 ] || [ `ps -A | grep -i -c BoxeeLauncher` -eq 1 ]; then
	/etc/rc3.d/U94boxeehal stop
	/etc/rc3.d/U99boxee stop
	killall BoxeeHal
	killall BoxeeLauncher
	killall Boxee
	killall run_boxee.sh
fi

/usr/local/DFBTerm/bin/dfbterm --dfb:no-cursor,no-linux-input-grab,init-layer=0,layer-format=ARGB,layer-buffer-mode=triple,layer-bg-color=00000000,primary-only -c \"/data/hack/misc/shell_no_password.sh\"

#
# Feel free to experiment with the --dfb: settings. The original RMA settings are:
#/usr/local/DFBTerm/bin/dfbterm --dfb:no-cursor,init-layer=0,layer-format=ARGB,layer-buffer-mode=triple,layer-bg-color=00000000,primary-only --fontsize=23 --position=35,20 --size=60x18  -c \"/data/hack/misc/shell.sh\"
#
# All settings can be found at: http://directfb.org/docs/directfbrc.5.html
# or http://www.directfb.org/wiki/index.php/Configuring_DirectFB