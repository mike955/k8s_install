#!/bin/bash

sh -c "echo 'PATH=/opt/k8s/bin:$PATH:$HOME/bin:$JAVA_HOME/bin' >>/root/.bashrc"
echo 'PATH=/opt/k8s/bin:$PATH:$HOME/bin:$JAVA_HOME/bin' >>~/.bashrc

# install dependency
yum install -y epel-release
yum install -y conntrack ipvsadm ipset jq sysstat curl iptables libseccomp
yum -y install net-tools

# stop firewalld
systemctl stop firewalld
systemctl disable firewalld
iptables -F && sudo iptables -X && sudo iptables -F -t nat && sudo iptables -X -t nat
iptables -P FORWARD ACCEPT

swapoff -a
sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

setenforce 0

cat > kubernetes.conf <<EOF
net.bridge.bridge-nf-call-iptables=1
net.bridge.bridge-nf-call-ip6tables=1
net.ipv4.ip_forward=1
vm.swappiness=0
vm.overcommit_memory=1
vm.panic_on_oom=0
fs.inotify.max_user_watches=89100
EOF

cp kubernetes.conf  /etc/sysctl.d/kubernetes.conf
modprobe br_netfilter
modprobe ip_vs
sysctl -p /etc/sysctl.d/kubernetes.conf
# mount -t cgroup -o cpu,cpuacct none /sys/fs/cgroup/cpu,cpuacct

# 调整系统 TimeZone
timedatectl set-timezone Asia/Shanghai

# 将当前的 UTC 时间写入硬件时钟
timedatectl set-local-rtc 0

# 重启依赖于系统时间的服务
systemctl restart rsyslog 
systemctl restart crond

mkdir -p /opt/k8s/bin
chown -R k8s /opt/k8s
mkdir -p /etc/kubernetes/cert
chown -R k8s /etc/kubernetes
mkdir -p /etc/etcd/cert
chown -R k8s /etc/etcd/cert
mkdir -p /var/lib/etcd && chown -R k8s /etc/etcd/cert