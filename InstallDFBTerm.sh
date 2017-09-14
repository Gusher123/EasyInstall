#!/bin/sh

server2="https://github.com/Gusher123/EasyInstall/raw/master"

case $1 in
    "nostart")
	# Make new /usr/local directory
	mkdir /data/hack/local_mnt
	# Copy the original /usr/local/ files
	cp -R /usr/local/* /data/hack/local_mnt/
	# Add the DFBTerm files
	curl $server2/DFBTerm.tgz -o /tmp/DFBTerm.tgz
	tar -x -f /tmp/DFBTerm.tgz -C /data/hack/
	# Install an extra init.d file to bind the /data/hack/local_mnt/ to /usr/local automatically at bootup 
	curl $server2/24DFBTerm.sh -o /data/hack/init.d/24DFBTerm.sh
	chmod 777 /data/hack/init.d/24DFBTerm.sh
	# Install a script to kill the Boxee software and start the terminal on HDMI out
	curl $server2/DFBTerm.sh -o /data/hack/bin/DFBTerm.sh
	chmod 777 /data/hack/bin/DFBTerm.sh
	# Install a shell with no password 
	curl $server2/shell_no_password.sh -o /data/hack/misc/shell_no_password.sh
	chmod 777 /data/hack/misc/shell_no_password.sh
	# Bind the /data/hack/local_mnt/ to /usr/local 
	sh /data/hack/init.d/24DFBTerm.sh
	;;
    *)
	# Make new /usr/local directory
	mkdir /data/hack/local_mnt
	# Copy the original /usr/local/ files
	cp -R /usr/local/* /data/hack/local_mnt/
	# Add the DFBTerm files
	curl $server2/DFBTerm.tgz -o /tmp/DFBTerm.tgz
	tar -x -f /tmp/DFBTerm.tgz -C /data/hack/
	# Install an extra init.d file to bind the /data/hack/local_mnt/ to /usr/local automatically at bootup 
	curl $server2/24DFBTerm.sh -o /data/hack/init.d/24DFBTerm.sh
	chmod 777 /data/hack/init.d/24DFBTerm.sh
	# Install a script to kill the Boxee software and start the terminal on HDMI out
	curl $server2/DFBTerm.sh -o /data/hack/bin/DFBTerm.sh
	chmod 777 /data/hack/bin/DFBTerm.sh
	# Install a shell with no password 
	curl $server2/shell_no_password.sh -o /data/hack/misc/shell_no_password.sh
	chmod 777 /data/hack/misc/shell_no_password.sh
	# Bind the /data/hack/local_mnt/ to /usr/local 
	sh /data/hack/init.d/24DFBTerm.sh
	# Start the terminal
	sh /data/hack/bin/DFBTerm.sh &
esac


