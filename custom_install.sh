#!/bin/bash

# Copyright (c) 2015, Bob Tidey
# All rights reserved.

# Redistribution and use, with or without modification, are permitted provided
# that the following conditions are met:
#    * Redistributions of source code must retain the above copyright
#      notice, this list of conditions and the following disclaimer.
#    * Neither the name of the copyright holder nor the
#      names of its contributors may be used to endorse or promote products
#      derived from this software without specific prior written permission.

# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY
# DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

rpicamdir=html
rpicamdirold=$rpicamdir

if [ ! "${rpicamdir:0:1}" == "" ]; then
   rpicamdirEsc="\\/$rpicamdir"
   rpicamdir=/$rpicamdir
else
   rpicamdirEsc=""
fi

fn_stop ()
{ # This is function stop
        sudo killall raspimjpeg
        sudo killall php
        sudo killall motion
}

fn_reboot ()
{ # This is function reboot system
  dialog --title "Start camera system now" --backtitle "$backtitle" --yesno "Start now?" 5 33
  response=$?
    case $response in
      0) ./start.sh;;
      1) dialog --title 'Start or Reboot message' --colors --infobox "\Zb\Z1"'Manually run ./start.sh or reboot!' 4 28 ; sleep 2;;
      255) dialog --title 'Start or Reboot message' --colors --infobox "\Zb\Z1"'Manually run ./start.sh or reboot!' 4 28 ; sleep 2;;
    esac
}

fn_stop

sudo mkdir -p /var/www$rpicamdir/media
#move old material if changing from a different install folder
if [ ! "$rpicamdir" == "$rpicamdirold" ]; then
   if [ -e /var/www$rpicamdirold/index.php ]; then
      sudo mv /var/www$rpicamdirold/* /var/www$rpicamdir
   fi
fi

sudo cp -r www/* /var/www$rpicamdir/
if [ -e /var/www$rpicamdir/index.html ]; then
   sudo rm /var/www$rpicamdir/index.html
fi

#Make sure user www-data has bash shell
sudo sed -i "s/^www-data:x.*/www-data:x:33:33:www-data:\/var\/www:\/bin\/bash/g" /etc/passwd

if [ ! -e /var/www$rpicamdir/FIFO ]; then
   sudo mknod /var/www$rpicamdir/FIFO p
fi
sudo chmod 666 /var/www$rpicamdir/FIFO

if [ ! -e /var/www$rpicamdir/FIFO1 ]; then
   sudo mknod /var/www$rpicamdir/FIFO1 p
fi
sudo chmod 666 /var/www$rpicamdir/FIFO1
sudo chmod 755 /var/www$rpicamdir/raspizip.sh

if [ ! -e /var/www$rpicamdir/cam.jpg ]; then
   sudo ln -sf /run/shm/mjpeg/cam.jpg /var/www$rpicamdir/cam.jpg
fi

if [ -e /var/www$rpicamdir/status_mjpeg.txt ]; then
   sudo rm /var/www$rpicamdir/status_mjpeg.txt
fi
if [ ! -e /run/shm/mjpeg/status_mjpeg.txt ]; then
   echo -n 'halted' > /run/shm/mjpeg/status_mjpeg.txt
fi
sudo chown www-data:www-data /run/shm/mjpeg/status_mjpeg.txt
sudo ln -sf /run/shm/mjpeg/status_mjpeg.txt /var/www$rpicamdir/status_mjpeg.txt

sudo chown -R www-data:www-data /var/www$rpicamdir
sudo cp etc/sudoers.d/RPI_Cam_Web_Interface /etc/sudoers.d/
sudo chmod 440 /etc/sudoers.d/RPI_Cam_Web_Interface

sudo cp -r bin/raspimjpeg /opt/vc/bin/
sudo chmod 755 /opt/vc/bin/raspimjpeg
if [ ! -e /usr/bin/raspimjpeg ]; then
   sudo ln -s /opt/vc/bin/raspimjpeg /usr/bin/raspimjpeg
fi

sed -e "s/www/www$rpicamdirEsc/" etc/raspimjpeg/raspimjpeg.1 > etc/raspimjpeg/raspimjpeg
if [ `cat /proc/cmdline |awk -v RS=' ' -F= '/boardrev/ { print $2 }'` == "0x11" ]; then
   sed -i 's/^camera_num 0/camera_num 1/g' etc/raspimjpeg/raspimjpeg
fi
if [ -e /etc/raspimjpeg ]; then
   $color_green; echo "Your custom raspimjpg backed up at /etc/raspimjpeg.bak"; $color_reset
   sudo cp -r /etc/raspimjpeg /etc/raspimjpeg.bak
fi
sudo cp -r etc/raspimjpeg/raspimjpeg /etc/
sudo chmod 644 /etc/raspimjpeg
if [ ! -e /var/www$rpicamdir/raspimjpeg ]; then
   sudo ln -s /etc/raspimjpeg /var/www$rpicamdir/raspimjpeg
fi

sudo usermod -a -G video www-data
if [ -e /var/www$rpicamdir/uconfig ]; then
   sudo chown www-data:www-data /var/www$rpicamdir/uconfig
fi

if [ -e /var/www$rpicamdir/uconfig ]; then
   sudo chown www-data:www-data /var/www$rpicamdir/uconfig
fi

if [ -e /var/www$rpicamdir/schedule.php ]; then
   sudo rm /var/www$rpicamdir/schedule.php
fi

sudo sed -e "s/www/www$rpicamdirEsc/g" www/schedule.php > www/schedule.php.1
sudo mv www/schedule.php.1 /var/www$rpicamdir/schedule.php
sudo chown www-data:www-data /var/www$rpicamdir/schedule.php

if [ $# -eq 0 ] || [ "$1" != "q" ]; then
   fn_reboot
fi
