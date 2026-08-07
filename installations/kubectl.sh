#!/bin/bash


#Download the latest release with the command:
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

#Download the kubectl checksum file:
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256"

#Validate
echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check

#Install kubectl
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

#After installation, do this step by step:
chmod +x kubectl
mkdir -p ~/.local/bin
mv ./kubectl ~/.local/bin/kubectl

#Ensure installation
kubectl version --client
