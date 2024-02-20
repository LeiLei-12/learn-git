#/bin/bash
read -p "请输入想要安装的docker版本:" version
sudo yum remove docker* >& /dev/null
sudo yum install -y yum-utils >& /dev/null
echo "正在添加docker源"
sudo yum-config-manager --add-repo https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo >&/dev/null
echo "正在安装docker"
sudo yum -y install docker-ce-$version docker-ce-cli-$version containerd.io >&/dev/null
systemctl start docker && systemctl enable docker >/dev/null
echo "正在配置JSON文件"
sudo mkdir -p /etc/docker
sudo tee /etc/docker/daemon.json <<-'EOF'
{
  "registry-mirrors": ["https://puibl78q.mirror.aliyuncs.com"],
  		"exec-opts": ["native.cgroupdriver=systemd"]
}
EOF
echo "docker$version安装完毕，正在启动"
sudo systemctl daemon-reload
sudo systemctl restart docker
