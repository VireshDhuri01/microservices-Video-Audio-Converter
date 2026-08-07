#!/bin/bash

wget https://get.helm.sh/helm-v3.21.3-linux-amd64.tar.gz

tar -zxvf helm-v3.21.3-linux-amd64.tar.gz

sudo mv linux-amd64/helm /usr/local/bin/helm

helm version
