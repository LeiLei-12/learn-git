# 安装部署kubeEdge（1.13.0）

[**https://github.com/kubeedge/kubeedge/releases/tag/v1.10.0 

Centos7.9+ kubernetes 1.23.8 + Docker 20.10.17

1、部署要求
请确保已经在云端部署好k8s集群。
KubeEdge部署要求

机器配置:
云端: CPU2核+，内存2GB+，硬盘30GB+
边缘: CPU1核+，内存256MB+
网络要求:
云端: 外网访问权限，开放 10000-10004 端口
边缘:外网访问权限
操作系统: ubuntu、 centos等
CPU架构: x86 64、arm64、arm32

## 1.首先准备好k8s集群

```shell
mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.backup
curl -o /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-7.repo
yum -y install epel-release 
yum makecache
systemctl disable firewalld 
systemctl stop firewalld
setenforce 0
sed -i 's/enforcing/disabled/' /etc/selinux/config
swapoff -a
sed -ri 's/.*swap.*/#&/' /etc/fstab
mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.backup
curl -o /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-7.repo
yum makecache
yum -y install vim wget tree bash-com* net-tools yum-utils epel-release ntpdate
cat << EOF > /etc/modules-load.d/k8s.conf
br_netfilter
EOF
cat <<EOF > /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv4.ip_forward = 1
EOF
modprobe br_netfilter
sudo sysctl --system

cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64/
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF
yum makecache
yum install -y kubelet-1.23.8 kubeadm-1.23.8 kubectl-1.23.8 --nogpgcheck
systemctl enable kubelet && systemctl start kubelet

[root@k8s-master ~]# kubeadm init \
  --apiserver-advertise-address=192.168.4.100 \
  --image-repository registry.aliyuncs.com/google_containers \
  --kubernetes-version v1.23.8 \
  --service-cidr=10.96.0.0/12 \
  --pod-network-cidr=10.244.0.0/16 \
  --ignore-preflight-errors=all
```



## 2.准备好以下两个文件上传到云端服务器

```shell
#  keadm-v1.13.0-linux-amd64.tar.gz
#  kubeedge-v1.13.0-linux-amd64.tar.gz
tar -zxvf keadm-v1.13.0-linux-amd64.tar.gz
cd keadm-v1.13.0-linux-amd64/keadm/
输入keadm version，如果能输出版本信息，说明安装成功
```

## 3.设置云端（注意：默认情况下需要开放10000，10002端口 ）

```shell
#注意：默认情况下需要开放10000，10002端口
在集群云端节点使用如下命令，将安装cloudcore，生成证书并安装CRD，–advertise-address指定云端的公开地址（边缘端可ping通的内网地址也可）
keadm init --advertise-address=192.168.4.100 --kube-config=/root/.kube/config --kubeedge-version=1.12.1
这是因为cloudcore没有污点容忍，默认master节点是不部署应用的，可以用下面的命令查看污点：
#kubectl describe nodes master | grep Taints
把master的污点删掉
#kubectl taint node master node-role.kubernetes.io/master-
# 然后重置
keadm reset
#再重新启动
这里很可能会因网络等问题下载不下来，或者运行出错等，可以具体问题具体分析，安装过程中我是在这一步遇到很多问题，但是现在也忘了，主要是网络问题吧，如果这里有问题可以留言一起沟通
#使用此命令会从gitHub上下载很多文件，网络有问题的用户，建议提前下载好，放置/etc/kubeedge目录下。
# cloudcore.service
# kubeedge-v1.13.0-linux-amd64.tar.gz
#netstat -tpnl
出现10000，和10002，这两个端口算正常。
```

### 1.获取token，边缘节点加入云端节点需要通过token认证方式，使用如下命令获取边缘节点加入集群的token： 

```shell
keadm gettoken
```

## 4.设置边缘端

```shell
同理先下载keadm，解压
# 1、下载
wget https://github.com/kubeedge/kubeedge/releases/download/v1.13.0/keadm-v1.13.0-linux-amd64.tar.gz

# 2、解压
tar -zxvf keadm-v1.13.0-linux-amd64.tar.gz

# 3、将其配置进入环境变量，方便使用
cd keadm-v1.13.0-linux-amd64/keadm/
cp keadm /usr/sbin/ #将其配置进入环境变量，方便使用
```

### 1.加入集群

```shell
keadm join --cloudcore-ipport=192.168.4.100:10000 --kubeedge-version=1.12.1 --with-mqtt --token=727beb571b45a708848c357cd420051a774a49e938759ecdfeecded38f8e030d.eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE2OTg4MDExODl9._VJRdbgdZDnMkE5lm-JDEzIUKOi2JyZKfOSk7rrpz8k
#这里也可能会因为网络原因下载失败，可以将文件提前下载好，创建/etc/kubeedge目录，将提前准备好的文件放入即可，边缘端所需文件如下，其余文件会自动生成。
# edgecore.service
# kubeedge-v1.13.0-linux-amd64.tar.gz
#启动edgecore      
systemctl start edgecore    

#设置开机自启
systemctl enable edgecore.service  

#查看edgecore开机启动状态 enabled:开启, disabled:关闭
systemctl is-enabled edgecore

#查看状态     
systemctl status edgecore 

#查看日志
journalctl -u edgecore.service -b
#主节点查看状态
kubectl get nodes -o wide
#查看kube-system安装
kubectl get pod -n kube-system
```

```
kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml
```

## 5.安装Kuboard

```shell
kubectl apply -f https://addons.kuboard.cn/kuboard/kuboard-v3.yaml
```

