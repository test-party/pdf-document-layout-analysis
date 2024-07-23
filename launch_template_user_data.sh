#!/bin/bash
sudo yum update -y

# install nvidia drivers and container toolkit
sudo yum install -y gcc make kernel-devel-$(uname -r)
aws s3 cp --recursive s3://ec2-linux-nvidia-drivers/latest/ .
sudo yum install kernel-modules-extra -y
chmod +x NVIDIA-Linux-x86_64*.run
sudo /bin/sh ./NVIDIA-Linux-x86_64*.run --silent
curl -s -L https://nvidia.github.io/libnvidia-container/stable/rpm/nvidia-container-toolkit.repo | sudo tee /etc/yum.repos.d/nvidia-container-toolkit.repo
sudo yum install -y nvidia-container-toolkit

# install docker
sudo yum install -y docker
sudo usermod -aG docker ec2-user
newgrp docker

# tell docker where to find the nvidia container runtime
sudo touch /etc/docker/daemon.json
sudo echo '{"runtimes": {"nvidia": {"path": "/usr/bin/nvidia-container-runtime", "runtimeArgs": []}}, "default-runtime": "nvidia"}' >> /etc/docker/daemon.json

# install ecs
curl -O https://s3.us-west-2.amazonaws.com/amazon-ecs-agent-us-west-2/amazon-ecs-init-latest.x86_64.rpm
sudo yum localinstall -y amazon-ecs-init-latest.x86_64.rpm

# configure ECS to point to the VGT cluster
sudo mkdir -p /etc/ecs
sudo touch /etc/ecs/ecs.config 
echo ECS_CLUSTER=vgt-cluster >> /etc/ecs/ecs.config
echo ECS_ENABLE_GPU_SUPPORT=true >> /etc/ecs/ecs.config
sudo sed -i -e 's/After=docker.service/After=cloud-final.service/g' /lib/systemd/system/ecs.service

# start Docker and ECS
sudo systemctl enable --now --no-block docker.socket
sudo systemctl enable --now --no-block docker.service
sudo systemctl enable --now --no-block ecs.service
