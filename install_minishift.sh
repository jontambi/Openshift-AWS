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
sysctl -p

wget https://github.com/openshift/origin/releases/download/v3.11.0/openshift-origin-client-tools-v3.11.0-0cbc58b-linux-64bit.tar.gz
tar xvf openshift-origin-client-tools*.tar.gz
cd openshift-origin-client*/
chmod +x *
cp oc kubectl  /usr/local/bin/
cp oc kubectl  /usr/bin/

oc cluster up --public-hostname=ec2-52-4-82-233.compute-1.amazonaws.com --routing-suffix=52.4.82.233
oc adm policy add-cluster-role-to-user cluster-admin developer

#After installation
oc -n istio-system expose svc/istio-ingressgateway --port=http2


#Maistra Installation
https://maistra-0-12-0--maistra.netlify.com/docs/getting_started/install/
https://access.redhat.com/solutions/4367311
https://github.com/kubernetes/kubernetes/issues/83038

#The node was low on resource: ephemeral-storage. Container galley was using 976Ki, which exceeds its request of 0

2020-04-12T15:45:45.920477Z     info    Envoy command: [-c /etc/istio/proxy/envoy.yaml --restart-epoch 0 --drain-time-s 45 --parent-shutdown-time-s 60 --service-cluster istio-policy --service-node sidecar~172.17.0.15~istio-policy-788d955874-7wcfv.istio-system~istio-system.svc.cluster.local --max-obj-name-len 189 --allow-unknown-fields -l warning]
2020-04-12T15:45:45.922929Z     info    watching /etc/certs for changes
[2020-04-12 15:45:45.967][13][warning][misc] [external/envoy/source/common/protobuf/utility.cc:174] Using deprecated option 'envoy.api.v2.Cluster.hosts' from file cds.proto. This configuration will be removed from Envoy soon. Please see https://www.envoyproxy.io/docs/envoy/latest/intro/deprecated for details.
[2020-04-12 15:45:45.967][13][warning][misc] [external/envoy/source/common/protobuf/utility.cc:174] Using deprecated option 'envoy.api.v2.Cluster.hosts' from file cds.proto. This configuration will be removed from Envoy soon. Please see https://www.envoyproxy.io/docs/envoy/latest/intro/deprecated for details.
[2020-04-12 15:45:45.967][13][warning][misc] [external/envoy/source/common/protobuf/utility.cc:174] Using deprecated option 'envoy.api.v2.Cluster.hosts' from file cds.proto. This configuration will be removed from Envoy soon. Please see https://www.envoyproxy.io/docs/envoy/latest/intro/deprecated for details.
