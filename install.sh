#!/bin/bash

echo '----------------- start install -----------------'

source environment.sh
for node_ip in ${NODE_IPS[@]}
  do
    echo ">>> ${node_ip}"
    scp environment.sh k8s@${node_ip}:/opt/k8s/bin/
    ssh k8s@${node_ip} "chmod +x /opt/k8s/bin/*"
  done

echo '----------------- start install CA ----------------------'
# install CA
sh ./install_ca.sh

echo '----------------- start install kubectl -----------------'
# install kubectl
sh ./install_kubectl.sh

echo '----------------- start install etcd --------------------'
# install etcd
sh ./install_etcd.sh

echo '----------------- start install flannel -----------------'
# install flannel
sh ./install_flannel.sh

echo '----------------- start install master ------------------'
# install master
sh ./install_master.sh

echo '----------------- start install node --------------------'
# install node
sh ./install_node.sh