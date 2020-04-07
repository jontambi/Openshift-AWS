# Instalacion Ansible Engine

sudo yum -y install epel-release
sudo yum -y install -y net-tools wget
sudo yum -y update

# Install the prerequisites
sudo yum -y install qemu-kvm*
sudo yum -y group install virtualization-host-environment
sudo yum -y update

# Enable libvirtd
sudo systemctl enable --now libvirtd
sudo usermod -a -G libvirt centos
newgrp - libvirt

systemctl is-active libvirtd
sudo systemctl start libvirtd

sudo virsh net-list --all
sudo virsh net-start default
sudo virsh net-autostart default

# Install KVM support
sudo su -
curl --location https://github.com/docker/machine/releases/download/v0.16.2/docker-machine-`uname -s`-`uname -m` > /usr/local/bin/docker-machine
chmod +x /usr/local/bin/docker-machine && \
curl --location https://github.com/dhiltgen/docker-machine-kvm/releases/download/v0.10.0/docker-machine-driver-kvm-centos7 > /usr/local/bin/docker-machine-driver-kvm && \
chmod +x /usr/local/bin/docker-machine-driver-kvm

# Install minishift
wget -qO- https://github.com/minishift/minishift/releases/download/v1.34.2/minishift-1.34.2-linux-amd64.tgz | tar --extract --gzip --verbose -C /tmp/
cp -p /tmp/minishift-1.34.2-linux-amd64/minishift /usr/bin/.
chmod +x /usr/bin/minishift