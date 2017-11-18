#!/bin/bash
# to be run as root

##
# Note - there are hostnames in here that need changing!!!
##

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
yum install -y --enablerepo=virt7-docker-common-release kubernetes docker

## Edit the configuration files
sed -i '/KUBE_MASTER/d' /etc/kubernetes/config
echo 'KUBE_MASTER="--master=http://kubernetes-master:8080"' >> /etc/kubernetes/config
echo 'KUBE_ETCD_SERVERS="--etcd-servers=http://kubernetes-master:2379"' >> /etc/kubernetes/config

sed -i '/KUBELET_ADDRESS/d' /etc/kubernetes/kubelet
sed -i '/The address for the info server to serve on/aKUBELET_ADDRESS="--address=0.0.0.0"' /etc/kubernetes/kubelet
sed -i '/KUBELET_PORT/d' /etc/kubernetes/kubelet
sed -i '/# The port for the info server to serve on/aKUBELET_PORT="--port=10250"' /etc/kubernetes/kubelet
sed -i '/KUBELET_HOSTNAME/d' /etc/kubernetes/kubelet
sed -i '/You may leave this blank to use the actual hostname/aKUBELET_HOSTNAME="--hostname-override=kubernetes-node1"' /etc/kubernetes/kubelet
sed -i '/KUBELET_API_SERVER/d' /etc/kubernetes/kubelet
sed -i '/location of the api-server/aKUBELET_API_SERVER="--api-servers=http://kubernetes-master:8080"' /etc/kubernetes/kubelet
sed -i '/KUBELET_POD_INFRA_CONTAINER/d' /etc/kubernetes/kubelet

# start services
systemctl enable kube-proxy kubelet docker
systemctl start kube-proxy kubelet docker