#!/bin/sh 
# Last Changed:  12-11-2015
#
# Startup script for PEM software

### BEGIN INIT INFO
# Provides:          pem.sh
# Required-Start:    $remote_fs cron
# Required-Stop:     $remote_fs
# Default-Start:     1 2 3 4 5
# Default-Stop:      0 6
# Short-Description: Start PEM nHD application at boot time
# Description:       Enable services for interfacing the LightCrafter 2000 driver board from BBB.
### END INIT INFO

set -e

PATH=/sbin:/bin:/usr/sbin:/usr/bin
test -x /usr/bin/nHD_pem || exit 0

. /lib/lsb/init-functions

case "$1" in
start|reload|force-reload|restart)

	# update firmware if file exists
	if test -f /var/tmp/ctemp; then
                echo "Updating nHD-PEM application ..."
		cp /usr/bin/nHD_pem /var/tmp/nHD_pem.old
		cp /var/tmp/ctemp /usr/bin/nHD_pem
		rm -f /var/tmp/ctemp 
	fi
	echo 48 > /sys/class/gpio/export
        echo out > /sys/class/gpio/gpio48/direction
        echo 1 > /sys/class/gpio/gpio48/value 	
	if test -f /usr/bin/nHD_pem; then
		echo "nHD-PEM application found and launching ..... "
                start-stop-daemon  -C -I real-time --start -m --pidfile /var/run/pem.pid --name nHD --exec /usr/bin/nHD_pem -b > /var/log/pem.log
		
	fi 

        ;;
stop)
       echo "Stopping nHD-PEM service..."
       set +e
#      start-stop-daemon  --stop -s 15 --pidfile /var/run/pem.pid --name nHD --exec /usr/bin/nHD_pem
       kill -15 `cat /var/run/pem.pid`
       set -e

        exit 0
        ;;
*)
        echo "Usage: /etc/init.d/pem.sh {start|stop|reload|restart|force-reload}"
        exit 1
        ;;
esac

exit 0
	echo "PEM Startup script completed."

