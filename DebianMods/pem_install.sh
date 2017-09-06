#!/bin/bash
# Last update:  08/28/2017
#
#    This script is designed to be ran on the BB from the directory where the install files are located.
# This means that the user has already pulled a copy of the install files (including this script)
# onto the BB either through git or some other means.  
#
#    Start with a clean Debian build. The following Debian Image file was used:
#       bone-debian-7.11-ixde-4gb-armhf-2016-06-15-4gb.img
#
#    To make this a "flasher" image after installing the img file onto a uSDcard, a line at the end of
#    the /boot/uEnv.txt file must be uncommented and changed to this:
#       cmdline=init=/opt/scripts/tools/eMMC/init-eMMC-flasher-v3-bbg.sh
#
#    After flashing the BBG, remove uSDcard and reboot.  Then Load the install script and related files 
#    from git using the following command line (public):
#	git clone https://github.com/keynotep/lc4500_pem
#
#    NOTE: This install script does require superuser priveleges (default) for some operations.
#
#    When run, it will perform several "install" operations for the following components:
#    - Links will be created for the startup script using update-rc.d command in /etc/init.d/
#    - compile the cape manager overlays (DTS) into DTBO files and place them into the cape manager folder
#    - update aptitude database and install various libraries required by the application
#    - Create folders needed by the LC4500-PEM application and make it auto-run on power-up
#    
#    A Reboot will be required after it completes
#
cur_dir=`pwd`

if [ -e /var/run/pem.pid ]; then
  echo "Stopping current application"
  sudo kill -15 `cat /var/run/pem.pid`
fi

cd
if [ -d nHD_pem_dev ]; then
  rm -f -r  nHD_pem_dev
fi

echo ========= Installing Startup Script and app ==========
# Now fix startup sequence
echo "Updating Boot-up scripts...."
cd /etc/init.d
# remove old startup scripts so we can rearrange them
sudo update-rc.d apache2 remove
sudo update-rc.d xrdp remove
sudo systemctl disable jekyll-autorun.service
sudo systemctl disable bonescript-autorun.service
# copy new versions with new priorities
#cp $cur_dir/StartupScripts/cron .
#cp $cur_dir/StartupScripts/dbus .
#cp $cur_dir/StartupScripts/rsync .
#cp $cur_dir/StartupScripts/udhcpd .
cp $cur_dir/StartupScripts/pem.sh .
sudo update-rc.d pem.sh start 10 1 2 3 4 5 . stop 0 0 6 .

echo ========= Installing Device Tree Overlays  =============
echo "Updating Device Tree Overlay files...."
cd /lib/firmware
sudo cp $cur_dir/BB-BONE-NHD-00A0.dts .
# compile device tree overlay functions (SPI, HDMI etc.)
dtc -O dtb -o BB-BONE-NHD-00A0.dtbo -b 0 -@ BB-BONE-NHD-00A0.dts
echo ============= Updating the Cape Manager ================
cd /etc/default
cp $cur_dir/capemgr .

#echo ============= Adding USB device rules file ================
#cd /etc/udev/rules.d
#cp $cur_dir/dlpc350-hid.rules ./55-dlpc350-hid.rules

echo ============= Check uEnv.txt boot parameters ================
echo "Updating uEnv.txt file. Previous version saved in /boot/uEnv.old.txt"
cd $cur_dir
cp /boot/uEnv.txt /boot/uEnv.old.txt
cp /boot/uEnv.txt ./uEnv.old
if [ -s uEnv.old ]; then
  echo "Using saved uEnv file"
  cat uEnv.old | sed  '/cmdline/s/quiet/quiet text/g' |  sed  '/BB-BONELT-HDMI,BB-BONELT-HDMIN/s/#cape_disable/cape_disable/g' | sed '/BB-BONE-EMMC-2G/s/cape_disable/#cape_disable/g' | awk '/uname/{print "optargs=\"consoleblank=0\""}1' > /boot/uEnv.txt
else
  cat /boot/uEnv.txt  | sed  '/cmdline/s/quiet/quiet text/g' |  sed  '/BB-BONELT-HDMI,BB-BONELT-HDMIN/s/#cape_disable/cape_disable/g' | sed '/BB-BONE-EMMC-2G/s/cape_disable/#cape_disable/g' | awk '/uname/{print "optargs=\"consoleblank=0\""}1' > /boot/uEnv.txt
fi

echo ============= Check Network config ================
echo Check /etc/hostname to be sure the network name is correct:
echo "  Type the new network hostname you want to use or just enter to use default."
echo "  (you have 30 seconds or default will be automatically used): [nHD-pem] "
read -t 30 newhostname
if [ "$newhostname" == "" ] ; then
   echo "Default network ID used: nHD-pem. Be careful if you have multiple units on your network!"
   sudo echo "nHD-pem" > /etc/hostname
else
   echo "OK, changing network ID to:  " $newhostname
   sudo echo $newhostname > /etc/hostname
fi

echo "Updating BeagleBone network IP address (/etc/network/interfaces)..."
cp interfaces /etc/network/.

echo "Updating Debitian libraries..."
echo ========= Running Aptitude Update ==========
sudo apt-get update
#echo ========= Running Aptitude Upgrade ==========
#sudo apt-get upgrade
echo ========= Removing unwanted drivers ==========
sudo apt-get remove apache2 -y
#removal of udhcp will prevent RNDIS from working
#sudo apt-get remove --auto-remove udhcpd -y
sudo apt-get remove dbus-x11 consolekit -y
sudo apt-get autoremove -y
echo ========= Installing new drivers ==========
sudo apt-get install libdrm2 -y
#sudo apt-get install udev -y
sudo apt-get install libudev-dev -y
sudo apt-get install libdrm-dev -y
#next 2 needed if using USB loop-back to control ASIC over USB instead of I2C
sudo apt-get install libusb-dev -y
sudo apt-get install libusb-1.0.0-dev

#commented out recompile of application for now
#echo "Building and installing new PEM application..."
cd $cur_dir
#make clean
#make all
sudo cp nHD_pem /usr/bin/.

#create solutions database directory
echo ========= Creating utility directories ==========
# Create Solution root directory
if [ -d /opt/nHDpem ] ; then
    echo "Solution directory exists"
else
    echo "Creating entire Solution directory tree"
    sudo mkdir /opt/nHDpem
    sudo mkdir /opt/nHDpem/data
    sudo mkdir /opt/nHDpem/data/bin
fi

# Create data directory
if [ -d /opt/nHDpem/data ] ; then
    echo "Solution directory exists"
else
    echo "Creating Solution directory"
    sudo mkdir /opt/nHDpem/data
fi

# Create/populate Script directory
if [ -d /opt/nHDpem/data/bin ] ; then
    echo "Utility directory exists"
else
    echo "Creating Utility directory"
    sudo mkdir /opt/nHDpem/data/bin
fi
#install solution manipulation scripts
cp Solutions/*.sh /opt/nHDpem/data/bin/.


# Create/populate Solution Archive directory
if [ -d /opt/nHDpem/data/archive ] ; then
    echo "Solution Archive directory exists"
else
    echo "Creating Solution Archive directory"
    sudo mkdir /opt/nHDpem/data/archive
fi
#cp Solutions/*.tar.gz /opt/nHDpem/data/archive/.

# Create actual Solutions directory
if [ -d /opt/nHD/data/nHD ] ; then
    echo "Solutions directory exists"
else
    echo "Creating Solutions directory"
    sudo mkdir /opt/nHDpem/data/nHD
fi

# Install Bit plane test for use in board checkout
#/opt/nHDpem/data/bin/PutSolution.sh BitPlane-Test
#echo "Bit plane test solution installed."
echo "Install additional solutions using the following command line:"
echo " /opt/nHDpem/data/bin/PutSolution.sh <Solution Name>"

echo ========= Installation complete ==========
if [ -s /usr/bin/nHD_pem ] ; then
   echo "Installation Successfull. Reboot now (enter y)?"

read -t 30 user_boot
if [ "$user_boot" == "" ] ; then
   echo "Exiting, please reboot manually!"
else
   echo "OK, rebooting..."
   sudo reboot
fi

else
   echo "Installation script failed!"
fi

