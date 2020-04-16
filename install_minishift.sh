# Instalacion Openshift Oringin 3.11

yum -y install epel-release
yum -y install -y net-tools wget vim htop
yum -y update

yum install -y yum-utils
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
yum install -y docker-ce docker-ce-cli containerd.io

usermod -aG docker $USER
usermod -aG docker centos

mkdir /etc/docker /etc/containers

tee /etc/containers/registries.conf<<EOF
[registries.insecure]
registries = ['172.30.0.0/16']
EOF

tee /etc/docker/daemon.json<<EOF
{
   "insecure-registries": [
     "172.30.0.0/16"
   ]
}
EOF

systemctl daemon-reload
systemctl start docker
systemctl enable docker

echo "net.ipv4.ip_forward = 1" | sudo tee -a /etc/sysctl.conf
echo "vm.max_map_count = 262144" | sudo tee -a /etc/sysctl.conf
sysctl -p
docker login registry.redhat.io

wget https://github.com/openshift/origin/releases/download/v3.11.0/openshift-origin-client-tools-v3.11.0-0cbc58b-linux-64bit.tar.gz
tar xvf openshift-origin-client-tools*.tar.gz
cd openshift-origin-client*/
chmod +x *
cp oc kubectl  /usr/local/bin/
cp oc kubectl  /usr/bin/

oc cluster up --public-hostname=ec2-3-212-183-189.compute-1.amazonaws.com --routing-suffix=3.212.183.189

oc adm policy add-cluster-role-to-user cluster-admin developer


# Install Guide
# https://maistra-0-12-0--maistra.netlify.app/docs/getting_started/install/
# https://maistra-0-12-0--maistra.netlify.app/docs/getting_started/custom-install/

# Kiali
# https://github.com/kiali/kiali/blob/master/operator/deploy/kiali/kiali_cr.yaml


