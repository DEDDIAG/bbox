#!/bin/bash

if [[ "$(id -u)" != "0" ]]; then
   echo "Running as root: sudo -E $0" 1>&2
   sudo -E "$0"
   exit
fi

BBOX_PATH="/opt/bbox"

if [[ -z "${HOUSE}" ]]; then
    echo "Please enter the house name (e.g. house0001): "
    read house_name
else
    echo "Using current house name: ${HOUSE}"
    house_name=${HOUSE}
fi

if [[ -z "${REMOTE_HOST}" ]]; then
    echo "Please enter the remote host (e.g. example.com): "
    read REMOTE_HOST
else
    echo "Using current remote host: ${$REMOTE_HOST}"
fi

# Set system wide environment variables
echo "HOUSE=${house_name}" >> /etc/environment
echo "REMOTE_HOST=${REMOTE_HOST}" >> /etc/environment
echo "BBOX_PATH=${BBOX_PATH}" >> /etc/environment

# Set Hostname
# HOSTNAME = HOUSE
sed -i 's/^\(hostname:\).*/\1 '"${house_name}"'/' /boot/user-data

# Install cron jobs
install -m644 cron.d/* /etc/cron.d/

# Install bbox systemd service
install -m644 systemd/bbox.service /etc/systemd/system/bbox.service
systemctl enable bbox.service

# Add gpio group if missing (used in container)
[[ $(getent group gpio) ]] || groupadd -g 997 gpio

# Config ttyS0
install -m644 boot/cmdline.txt /boot/cmdline.txt

SSH_PATH=${HOME}/.ssh

# Generate SSH Key
if [[ ! -f  ${SSH_PATH}/id_rsa.pub ]]; then                   # if there is no ssh-key on the host
    mkdir -p ${SSH_PATH}
    echo GENERATING NEW SSH-KEY
    ssh-keygen -b 3072 -q -N "" -f ${SSH_PATH}/id_rsa       # ssh-keygen will create a 3072 bit key
    echo "--------------SSH public key for ${house_name}-----------------"
    cat ${SSH_PATH}/id_rsa.pub
    echo "-----------------------------------------------------------------"
    chown -R $(logname) ${SSH_PATH}
fi


# SWAP File
DPHYS_PKG="dphys-swapfile"
install -m644 dphys-swapfile/dphys-swapfile /etc/dphys-swapfile
if [[ $(dpkg-query -W -f='${Status}' ${DPHYS_PKG} 2>/dev/null | grep -c "ok installed") -eq 0 ]]; then
    echo "Installing ${DPHYS_PKG}"
    apt-get update && apt-get install -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" ${DPHYS_PKG}
fi

# CRON
systemctl enable cron

echo SYSTEM MUST BE REBOOTED
