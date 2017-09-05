nHD-PEM Configuration READMe.txt
++++++++++++++++++++++++++++++++++++

The files in this folder are intended to be used to modify the default install of the Debian:
=====================================================================================================================
 - Use Windows Win32DiskImager to create the flasher uSD Card to be used to initialize BBB with this image file:

   bone-debian-7.11-lxde-4gb-armhf-2016-06-15-4gb.img

 - Insert uSD Card into BBB and boot the card while holding config switch during startup to begin NAND flash reprogramming.
 - After running the flasher uSDcard to install the default Debian build, boot the board without the uSDcard and verify the version:

  cat /etc/dogtag 
or 
  cat /ID.txt 
or
  cat /etc/debian_version

 - Optionally modify the name of the board (default = 'beaglebone') here:

  vi /etc/hostname


==> Run the script to  install the needed components into the BB environment:
 
 cd DebianMods
 ./pem_install.sh
(This is the script to install files if they are already on the BB)

==> You may need to manually log into the BB and edit /boot/uEnv.txt:
   - Add the following line to remove 10 minute display turn-off
 optargs="consoleblank=0"
   - Turn off X-Windows by adding the word 'text' to the command line.  It should look something like this when you are done:
 cmdline=text dms.debug=7 coherent_pool=1M quiet init=/lib/systemd/systemd
   - Uncomment the line that disables HDMI.  It is not compatible with SPI or the DRM modes used in the DDM application.
 ##Disable HDMI (v3.8.x)
 cape_disable=capemgr.disable_partno=BB-BONELT-HDMI,BB-BONELT-HDMIN

