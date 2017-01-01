#!/bin/bash
set -e

echo -e "RancherOS Vagrant box builder."

RANCHEROS_VERSION=${1:-v0.7.1}

DM_VM_NAME="vagrant-ros-vm1"
TMP_VM_NAME="vagrant-ros-vm2"

CACHE_DIR=$(pwd)/cache

TMP_HDD_PATH=$CACHE_DIR/tmp_sda.vdi
HDDPATH=$CACHE_DIR/sda.vdi

ISO_BASE_PATH=$CACHE_DIR/iso/$RANCHEROS_VERSION
ISO_PATH=$ISO_BASE_PATH/rancheros.iso
CHECKSUM_PATH=$ISO_BASE_PATH/iso-checksums.txt

[ -d $ISO_BASE_PATH ] || mkdir -p $ISO_BASE_PATH

echo -e "RancherOS Version: $RANCHEROS_VERSION"

if [ ! -f $ISO_PATH ]; then
    echo "\n* Downloading RancherOS $RANCHEROS_VERSION ..."
    wget https://github.com/rancher/os/releases/download/$RANCHEROS_VERSION/rancheros.iso -O $ISO_PATH >$ISO_BASE_PATH/wget.log 2>&1
fi

# if [ ! -f $CHECKSUM_PATH ]; then
#     echo "* Downloading RancherOS $RANCHEROS_VERSION checksum data ..."
#     wget -q https://github.com/rancher/os/releases/download/$RANCHEROS_VERSION/iso-checksums.txt -O $CHECKSUM_PATH
# fi

echo "\n* Creating docker-machine based VM ..."
docker-machine create -d virtualbox --virtualbox-boot2docker-url rancheros.iso $DM_VM_NAME
docker-machine stop $DM_VM_NAME

echo "\n* Creating and attaching new HDD device ..."
VBOXMANAGE createhd --filename $TMP_HDD_PATH --size 8000
VBOXMANAGE storageattach $DM_VM_NAME --storagectl "SATA" --port 2 --device 0 --type hdd --medium $TMP_HDD_PATH
docker-machine start $DM_VM_NAME

echo "\n* Installing RancherOS on hard disk. It may take several minutes ..."
docker-machine ssh $DM_VM_NAME "cat >./vagrant.yml<<EOF
#cloud-config
ssh_authorized_keys:
  - ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA6NF8iallvQVp22WDkTkyrtvp9eWW6A8YVr+kz4TjGYe7gHzIw+niNltGEFHzD8+v1I2YJ6oXevct1YeS0o9HZyN1Q9qgCgzUFtdOKLv6IedplqoPkcmF0aYet2PkEDo3MlTBckFXPITAMzF8dJSIFo9D8HfdOV0IAdx4O7PtixWKn5y2hMNG0zQPyUecp4pzC6kivAIhyfHilFR61RGL+GPXQ2MWZWFYbAGjyiYJnAmCP3NOTd0jMZEnDkbUvxhMmBYSdETk1rRgm+R4LOzFUGaHqHDLKLX+FIPKcF96hrucXzcWyLbIbEgE98OHlnVYCzRdK8jlqm8tehUc9c9WhQ== vagrant insecure public key
EOF"

docker-machine ssh $DM_VM_NAME sudo ros install -d /dev/sdb -f -c ./vagrant.yml --no-reboot

echo "\n* RancherOS Installed successfully. Removing VM ..."

docker-machine stop $DM_VM_NAME
cp $TMP_HDD_PATH $HDDPATH
docker-machine rm -f $DM_VM_NAME

sleep 5

echo "\n* Building new VM ..."
vboxmanage createvm --name $TMP_VM_NAME --ostype "Linux_64" --register
vboxmanage modifyvm $TMP_VM_NAME --memory 2048 --vram 8 --acpi on --ioapic on --cpus 1
vboxmanage modifyvm $TMP_VM_NAME --nic1 nat --cableconnected1 on
vboxmanage modifyvm $TMP_VM_NAME --audio none

echo "\n* Extracting Vagrant box file ..."

vboxmanage storagectl $TMP_VM_NAME --name "SATA controller" --add sata
vboxmanage storageattach $TMP_VM_NAME --storagectl "SATA controller" --port 0 --device 0 --type hdd --medium $HDDPATH

vagrant package --base $TMP_VM_NAME --output rancheros_$RANCHEROS_VERSION.box

vboxmanage unregistervm $TMP_VM_NAME --delete
