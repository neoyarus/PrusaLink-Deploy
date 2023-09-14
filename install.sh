sudo apt install wpasupplicant git python3-pip libcap-dev libmagic1 libturbojpeg libatlas-base-dev python3-numpy python3-dev
pip install git+https://github.com/prusa3d/gcode-metadata.git
pip install git+https://github.com/prusa3d/Prusa-Connect-SDK-Printer.git@0.7.0
pip install git+https://github.com/prusa3d/Prusa-Link.git@0.7.0
sudo usermod -a -G dialout rock

sudo tee /etc/rc.local << 'EOF'
#!/bin/sh -e
#
# rc.local
#
# This script is executed at the end of each multiuser runlevel.
# Make sure that the script will "exit 0" on success or any other
# value on error.
#
# In order to enable or disable this script just change the execution
# bits.
#
# By default this script does nothing.

if [ -e /etc/first_boot ]; then
    /bin/sh /etc/first_boot
    rm /etc/first_boot
    reboot
fi

iptables -t nat -A PREROUTING -i wlan0 -p tcp --dport 80 -j REDIRECT --to-port 8080
iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 80 -j REDIRECT --to-port 8080
iptables -t nat -I OUTPUT -p tcp -o lo -d localhost --dport 80 -j REDIRECT --to-ports 8080

set_up_port () {
   # Sets the baudrate and cancels the hangup at the end of a connection
   stty -F "$1" 115200 -hupcl;
}

message() {
   printf "M117 $2\n" > "$1"
}

username=rock
user_site=$(su $username -c "python -m site --user-site")

set_up_port "/dev/ttyAML1"
message "/dev/ttyAML1" "Starting PrusaLink";

#$user_site/prusa/link/data/config_copy.sh
rm -f /home/$username/prusalink.pid
export PYTHONOPTIMIZE=2
su $username -c "/home/rock/.local/bin/prusalink start --serial-port /dev/ttyAML1"

exit 0
EOF

sudo chmod +x /etc/rc.local

sudo tee /lib/systemd/system/rc-local.service << 'EOF' 
#  SPDX-License-Identifier: LGPL-2.1-or-later
#
#  This file is part of systemd.
#
#  systemd is free software; you can redistribute it and/or modify it
#  under the terms of the GNU Lesser General Public License as published by
#  the Free Software Foundation; either version 2.1 of the License, or
#  (at your option) any later version.

# This unit gets pulled automatically into multi-user.target by
# systemd-rc-local-generator if /etc/rc.local is executable.
[Unit]
Description=/etc/rc.local Compatibility
Documentation=man:systemd-rc-local-generator(8)
ConditionFileIsExecutable=/etc/rc.local
After=network.target

[Service]
Type=forking
ExecStart=/etc/rc.local start
TimeoutSec=0
RemainAfterExit=yes
GuessMainPID=no
EOF

sudo ln -s /lib/systemd/system/rc-local.service /etc/systemd/system/rc-local.service

sudo systemctl enable rc-local.service

sudo shutdown -r now




