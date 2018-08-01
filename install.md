1. 设置三台机器主机名， 然后 *重新登陆*
```sh
hostnamectl set-hostname kube-node1
hostnamectl set-hostname kube-node2
hostnamectl set-hostname kube-node3
```

2. 修改三台机器的 /etc/hosts 文件，修改内容如下
```sh
192.168.16.68 kube-node1 kube-node1
192.168.17.235 kube-node2 kube-node2
192.168.16.209 kube-node3 kube-node3
```

4. 添加 k8s 和 docker 账户

在每台机器上添加 k8s 账户，可以无密码 sudo：

``` bash
$ sudo useradd -m k8s
$ sudo sh -c 'echo 123456 | passwd k8s --stdin' # 为 k8s 账户设置密码
$ sudo visudo
$ sudo grep '%wheel.*NOPASSWD: ALL' /etc/sudoers
%wheel	ALL=(ALL)	NOPASSWD: ALL
$ sudo gpasswd -a k8s wheel
```

在每台机器上添加 docker 账户，将 k8s 账户添加到 docker 组中，同时配置 dockerd 参数：

``` bash
useradd -m docker
gpasswd -a k8s docker
mkdir -p  /etc/docker/
```

4. 无密码 ssh 登录其它节点

```sh
ssh-keygen -t rsa
ssh-copy-id root@kube-node1
ssh-copy-id root@kube-node2
ssh-copy-id root@kube-node3

ssh-copy-id k8s@kube-node1
ssh-copy-id k8s@kube-node2
ssh-copy-id k8s@kube-node3
```

5. master 修改 iptables
   
把以下命令写入 /etc/rc.local 文件中，防止节点重启iptables FORWARD chain的默认策略又还原为DROP

```sh
/sbin/iptables -P FORWARD ACCEPT
```

6. 修改environment.sh环境变量
   
7. 执行相关安装准备

 4.1 master 节点上关闭SELinux
 ```bash
    grep SELINUX /etc/selinux/config 
    SELINUX=disabled
 ```
 4.2 master 节点上执行 before_install_master.sh
 4.3 node 节点上执行 before_install_node.sh

8. master 上执行安装

```bash
sh ./install.sh
```

9.  install coredns

```bash
kubectl create -f files/plugins/dns/coredns.yaml
kubectl get all -n kube-system | grep dns
```

10. install dashboard

```bash
kubectl create -f files/plugins/dashboard/*.yaml
kubectl get deployment kubernetes-dashboard  -n kube-system
kubectl --namespace kube-system get pods -o wide
kubectl get services kubernetes-dashboard -n kube-system
```
### 创建登录 Dashboard 的 token 和 kubeconfig 配置文件

```sh
kubectl create sa dashboard-admin -n kube-system
kubectl create clusterrolebinding dashboard-admin --clusterrole=cluster-admin --serviceaccount=kube-system:dashboard-admin
ADMIN_SECRET=$(kubectl get secrets -n kube-system | grep dashboard-admin | awk '{print $1}')
DASHBOARD_LOGIN_TOKEN=$(kubectl describe secret -n kube-system ${ADMIN_SECRET} | grep -E '^token' | awk '{print $2}')
echo ${DASHBOARD_LOGIN_TOKEN}


source /opt/k8s/bin/environment.sh
# 设置集群参数
kubectl config set-cluster kubernetes \
  --certificate-authority=/etc/kubernetes/cert/ca.pem \
  --embed-certs=true \
  --server=${KUBE_APISERVER} \
  --kubeconfig=dashboard.kubeconfig

# 设置客户端认证参数，使用上面创建的 Token
kubectl config set-credentials dashboard_user \
  --token=${DASHBOARD_LOGIN_TOKEN} \
  --kubeconfig=dashboard.kubeconfig

# 设置上下文参数
kubectl config set-context default \
  --cluster=kubernetes \
  --user=dashboard_user \
  --kubeconfig=dashboard.kubeconfig

# 设置默认上下文
kubectl config use-context default --kubeconfig=dashboard.kubeconfig

```

11. install heapster

```bash
kubectl create -f ./files/plugins/heapster-1.5.3/deploy/kube-config/infludb/*.yaml
```

```bash
kubectl create -f ./files/plugins/heapster-1.5.3/deploy/kube-config/rbac/*.yaml
```

```bash
kubectl get pods -n kube-system | grep -E 'heapster|monitoring'
```

12. install EFK

```bash
kubectl label nodes kube-node3 beta.kubernetes.io/fluentd-ds-ready=true
kubectl create -f ./files/plugins/fluentd-elasticsearch/*.yaml
```

```bash
kubectl get pods -n kube-system -o wide|grep -E 'elasticsearch|fluentd|kibana'
```

```bash
kubectl cluster-info|grep -E 'Elasticsearch|Kibana'
```