

1. 设置三台机器主机名， 然后重新登陆
```sh
hostnamectl set-hostname kube-node1
```

2. 修改三台机器的 /etc/hosts 文件，修改内容如下
```sh
192.168.xxx.xx kube-node1 kube-node1
192.168.xxx.xx kube-node2 kube-node2
192.168.xxx.xx kube-node3 kube-node3
```

3. 添加 k8s 和 docker 账户

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
$ sudo useradd -m docker
$ sudo gpasswd -a k8s docker
$ sudo mkdir -p  /etc/docker/
$ cat /etc/docker/daemon.json
{
    "registry-mirrors": ["https://hub-mirror.c.163.com", "https://docker.mirrors.ustc.edu.cn"],
    "max-concurrent-downloads": 20
}
```

4. 无密码 ssh 登录其它节点

如果没有特殊指明，本文档的所有操作**均在 kube-node1 节点上执行**，然后远程分发文件和执行命令。
设置 kube-node1 可以无密码登录**所有节点**的 k8s 和 root 账户：

``` bash
[k8s@kube-node1 k8s]$ ssh-keygen -t rsa
[k8s@kube-node1 k8s]$ ssh-copy-id root@kube-node1
[k8s@kube-node1 k8s]$ ssh-copy-id root@kube-node2
[k8s@kube-node1 k8s]$ ssh-copy-id root@kube-node3

[k8s@kube-node1 k8s]$ ssh-copy-id k8s@kube-node1
[k8s@kube-node1 k8s]$ ssh-copy-id k8s@kube-node2
[k8s@kube-node1 k8s]$ ssh-copy-id k8s@kube-node3
```

4. 安装相关依赖
   
```sh
sh ./install_depen.sh
```

5. 创建目录
在每台机器上创建目录
```sh
$ sudo mkdir -p /opt/k8s/bin
$ sudo chown -R k8s /opt/k8s

$ sudo sudo mkdir -p /etc/kubernetes/cert
$ sudo chown -R k8s /etc/kubernetes

$ sudo mkdir -p /etc/etcd/cert
$ sudo chown -R k8s /etc/etcd/cert

$ sudo mkdir -p /var/lib/etcd && chown -R k8s /etc/etcd/cert
```

6. 分发集群环境变量
将全局变量脚本拷贝到所有节点的 /opt/k8s/bin 目录，环境变量参考 ./environment.sh 文件

```sh
source environment.sh
for node_ip in ${NODE_IPS[@]}
  do
    echo ">>> ${node_ip}"
    scp environment.sh k8s@${node_ip}:/opt/k8s/bin/
    ssh k8s@${node_ip} "chmod +x /opt/k8s/bin/*"
  done
```

7. install CA

```sh
sh ./install_ca.sh
```

8. install kubectl

```sh
sh ./install_kubectl.sh
```

9. install etcd

```sh
sh install_etcd.sh
```

10.  install flannel

```sh
sh install_flannel.sh
```

11.  install master

```sh
sh install_master.sh
```

12.  install coredns

```bash
kubectl create -f files/plugins/dns/coredns.yaml
kubectl get all -n kube-system | grep dns
```

13. install dashboard

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

14. install heapster

```bash
kubectl create -f ./files/plugins/heapster-1.5.3/deploy/kube-config/infludb/*.yaml
```

```bash
kubectl create -f ./files/plugins/heapster-1.5.3/deploy/kube-config/rbac/*.yaml
```

```bash
kubectl get pods -n kube-system | grep -E 'heapster|monitoring'
```

15. install EFK

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