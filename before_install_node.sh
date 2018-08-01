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

mkdir -p /opt/k8s/bin
chown -R k8s /opt/k8s
mkdir -p /etc/kubernetes/cert
chown -R k8s /etc/kubernetes
mkdir -p /etc/etcd/cert
chown -R k8s /etc/etcd/cert
mkdir -p /var/lib/etcd && chown -R k8s /etc/etcd/cert