#!/bin/sh

THEPATH='/tmp/dialog:/data/hack/bin:/opt/local/bin:/usr/local/bin:/usr/bin:/bin:/opt/local/sbin:/usr/local/sbin:/usr/sbin:/sbin:/scripts'

for f in /data/plugins/*; do
        if [ -d ${f}/bin ]; then
                THEPATH="${f}/bin:${THEPATH}"
        fi
done

export PATH="${THEPATH}"
export LD_LIBRARY_PATH='.:/usr/local/DFBTerm/lib:/data/hack/lib:/opt/local/lib:/usr/local/lib:/usr/lib:/lib:/lib/gstreamer-0.10:/opt/local/lib/qt'
export HOME='/tmp'
export ENV='/data/etc/.profile'
export TERM=vt102
export TERMINFO='/share/terminfo/'

        echo "------------------------"
        echo " Welcome to Boxee+Hacks "
        echo "------------------------"

        cd /tmp

        /bin/sh
