#!/bin/bash
sudo yum update -y
sudo yum install -y docker
sudo systemctl start docker
sudo systemctl enable docker
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
curl -sL "https://raw.githubusercontent.com/Eliton-jpg/Atividade-Docker-Compasso/main/docker-compose.yaml" --output "/home/ec2-user/docker-compose.yaml"

sudo yum install amazon-efs-utils -y
sudo systemctl enable nfs-utils.service
sudo systemctl start nfs-utils.service

sudo mkdir -p /mnt/efs/
chmod +rwx /mnt/efs/
mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport fs-0104dbb46333af958.efs.us-east-1.amazonaws.com:/ /mnt/efs/
echo "fs-0104dbb46333af958.efs.us-east-1.amazonaws.com:/ /mnt/efs nfs defaults 0 0" >> /etc/fstab

docker-compose -f /home/ec2-user/docker-compose.yaml up -d