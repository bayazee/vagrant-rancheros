#!/bin/bash
set -xe

DM_VM_NAME="vagrant_ros_v1"
TMP_VM_NAME="vagrant_ros_vm2"

CACHE_DIR=$(pwd)/cache

TMP_HDD_PATH=$CACHE_DIR/tmp_sda.vdi
HDDPATH=$CACHE_DIR/sda.vdi

[ -d $CACHE_DIR ] || mkdir $CACHE_DIR

docker-machine create -d virtualbox --virtualbox-boot2docker-url rancheros.iso $DM_VM_NAME
docker-machine stop $DM_VM_NAME
VBOXMANAGE createhd --filename $TMP_HDD_PATH --size 8000
VBOXMANAGE storageattach $DM_VM_NAME --storagectl "SATA" --port 2 --device 0 --type hdd --medium $TMP_HDD_PATH
docker-machine start $DM_VM_NAME

docker-machine ssh $DM_VM_NAME "cat >./vagrant.yml<<EOF
#cloud-config
ssh_authorized_keys:
  - ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA6NF8iallvQVp22WDkTkyrtvp9eWW6A8YVr+kz4TjGYe7gHzIw+niNltGEFHzD8+v1I2YJ6oXevct1YeS0o9HZyN1Q9qgCgzUFtdOKLv6IedplqoPkcmF0aYet2PkEDo3MlTBckFXPITAMzF8dJSIFo9D8HfdOV0IAdx4O7PtixWKn5y2hMNG0zQPyUecp4pzC6kivAIhyfHilFR61RGL+GPXQ2MWZWFYbAGjyiYJnAmCP3NOTd0jMZEnDkbUvxhMmBYSdETk1rRgm+R4LOzFUGaHqHDLKLX+FIPKcF96hrucXzcWyLbIbEgE98OHlnVYCzRdK8jlqm8tehUc9c9WhQ== vagrant insecure public key
EOF"

docker-machine ssh $DM_VM_NAME sudo ros install -d /dev/sdb -f -c ./vagrant.yml --no-reboot

docker-machine stop $DM_VM_NAME
cp $TMP_HDD_PATH $HDDPATH
docker-machine rm -f $DM_VM_NAME

sleep 5

vboxmanage createvm --name $TMP_VM_NAME --ostype "Linux_64" --register
vboxmanage modifyvm $TMP_VM_NAME --memory 2048 --vram 8 --acpi on --ioapic on --cpus 1
vboxmanage modifyvm $TMP_VM_NAME --nic1 nat --cableconnected1 on
vboxmanage modifyvm $TMP_VM_NAME --audio none


# Add HDD and SATA controller
vboxmanage storagectl $TMP_VM_NAME --name "SATA controller" --add sata
vboxmanage storageattach $TMP_VM_NAME --storagectl "SATA controller" --port 0 --device 0 --type hdd --medium $HDDPATH

vagrant package --base $TMP_VM_NAME --output m2.box

vboxmanage unregistervm $TMP_VM_NAME --delete
rm -rf $CACHE_DIR
