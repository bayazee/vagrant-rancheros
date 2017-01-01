# RancherOS Vagrant Support
Since [RancherOS official Vagrant](https://github.com/rancher/os-vagrant) project is deprecated, the aim of this project is to build a working and updated vagrant box for _RancherOS_.

## Why?!
RancherOS team stopped supporting Vagrant and the Vagrant box have not got any update since last year. The problem is that RancherOS eliminated password based ssh login so it is not easy to boot and use it with Vagrant.

RancherOS officially supports `docker-machine`. The process of booting and injecting ssh key done by some kind of [magic](https://github.com/boot2docker/boot2docker/blob/master/rootfs/rootfs/etc/rc.d/automount)! So in this project we use `docker-machine` and its magic to create a VM and install RancherOS on disk and then make a Vagrant box from this VM.

## Dependencies
* Docker-machine
* Vagrant
* Virtualbox
