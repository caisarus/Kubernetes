#!/bin/bash
# to be run as root

# Setup NTPD server and NTP to ensure that the time across the cluster is as synchronised as possible
yum -y install ntp
sed -i '/restrict ::1/arestrict 10.0.0.0 mask 255.255.255.0 nomodify notrap/' /etc/ntp.conf
systemctl start ntpd
systemctl enable ntpd

# Add the Docker Repo
cat > virt7-docker-common-release.repo <<EOF
[virt7-docker-common-release]
name=virt7-docker-common-release
baseurl=http://cbs.centos.org/repos/virt7-docker-common-release/x86_64/os/
gpgcheck=0
EOF
mv virt7-docker-common-release.repo /etc/yum.repos.d/
yum update

# Install etcd - communication value sharing across cluster plus kubernetes
yum install -y --enablerepo=virt7-docker-common-release kubernetes docker etcd

## Edit the configuration files for the master
sed -i '/KUBE_MASTER/d' /etc/kubernetes/config
echo 'KUBE_MASTER="--master=http://kubernetes-master:8080"' >> /etc/kubernetes/config
echo 'KUBE_ETCD_SERVERS="--etcd-servers=http://kubernetes-master:2379"' >> /etc/kubernetes/config

sed -i '/ETCD_LISTEN_CLIENT_URLS/d' /etc/etcd/etcd.conf
sed -i '/ETCD_LISTEN_PEER_URLS/aETCD_LISTEN_CLIENT_URLS="http://0.0.0.0:2379"' /etc/etcd/etcd.conf
sed -i '/ETCD_ADVERTISE_CLIENT_URLS/d' /etc/etcd/etcd.conf
sed -i '/ETCD_INITIAL_CLUSTER_TOKEN/aETCD_ADVERTISE_CLIENT_URLS="http://0.0.0.0:2379"' /etc/etcd/etcd.conf
sed -i '/KUBE_API_ADDRESS/d' /etc/kubernetes/apiserver
sed -i '/# The address on the local server to listen to./aKUBE_API_ADDRESS="--address=0.0.0.0"' /etc/kubernetes/apiserver
sed -i '/KUBE_API_PORT/d' /etc/kubernetes/apiserver
sed -i '/# The port on the local server to listen on./aKUBE_API_PORT="--port=8080"' /etc/kubernetes/apiserver
sed -i '/KUBELET_PORT/d' /etc/kubernetes/apiserver
sed -i '/Port minions listen on/aKUBELET_PORT="--kubelet-port=10250"' /etc/kubernetes/apiserver
sed -i '/KUBE_ADMISSION_CONTROL/d' /etc/kubernetes/apiserver

# Enable Services
systemctl enable etcd kube-apiserver kube-controller-manager kube-scheduler
systemctl start etcd kube-apiserver kube-controller-manager kube-scheduler