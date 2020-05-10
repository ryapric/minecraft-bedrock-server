#!/usr/bin/env bash

# Assumed to be run on an Ubuntu host

# Set workdir
set-workdir() {
  cd /root || exit 1
}

# Primary update
apt-get update

# Install core sysutils
install-core-utils() {
  printf "Installing core system utilities...\n"
  apt-get install -y \
    awscli \
    curl \
    jq \
    tar \
    zip \
    unzip \
    python3 \
    python3-pip
}

# Install Docker and Docker Compose
install-docker() {
  printf "Installing Docker...\n"
  apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common
  
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -

  add-apt-repository \
    "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
  
  apt-get update && apt-get install -y docker-ce docker-ce-cli containerd.io

  pip3 install docker-compose
}

install-efs-utils() {
  printf "Installing efs-utils...\n"
  set-workdir
  apt-get install -y \
    git \
    binutils
  git clone https://github.com/aws/efs-utils
  cd efs-utils && ./build-deb.sh
  apt-get -y install ./build/amazon-efs-utils*deb
}

mount-efs() {
  printf "Mounting EFS, and setting to auto-mount...\n"
  mkdir /mnt/efs
  mount -t efs fs-1441f9f9 /mnt/efs/
  # Also make sure it auto-mounts on future boots
  echo "fs-1441f9f9 /mnt/efs efs _netdev 0 0" >> /etc/fstab
}

download-source() {
  printf "Downloading Bedrock Server source code from S3...\n"
  set-workdir
  aws s3 cp "s3://${bucket}/source.tar.gz" . && tar -xzf source.tar.gz
}

deploy-bedrock-server() {
  set-workdir
  instance_id=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
  nametag=$(aws ec2 describe-tags --filters "Name=resource-id,Values=${instance_id}" | jq -r '.Tags[] | select(.Key=="Name") | .Value')
  if [[ "${nametag}" == "bedrock-server-doorknocker" ]]; then
    compose_file=$(find . -name "*doorknocker-compose.yaml")
  elif [[ "${nametag}" == "bedrock-server-worker" ]]; then
    compose_file=$(find . -name "*bedrock-server-compose.yaml")
  else
    printf "ERROR -- Couldn't determine which docker-compose file to use based on Instance tag! \n" 2>&1
  fi
  docker-compose -f "bedrock-server/${compose_file}" up -d --build
}

main() {
  install-core-utils

  # Set AWS-dependent and config, now that the core utils are confirmed installed
  export AWS_REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone | sed 's/\(.*\)[a-z]/\1/')
  export accountNumber=$(aws sts get-caller-identity --query Account --output text)
  export bucket="minecraft-bedrock-server-${accountNumber}"
  export efs_fsid=$(aws efs describe-file-systems | jq -r '.FileSystems[] | select(.Name=="bedrock-server-efs") | .FileSystemId')
  
  install-docker

  install-efs-utils
  mount-efs

  download-source
  deploy-bedrock-server
}

main
