#!/bin/bash

curl -sL https://rpm.nodesource.com/setup_14.x | sudo -E bash -
sudo yum install -y nodejs

node --version

# Install Ops Agent
curl -sSO https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh
sudo bash add-google-cloud-ops-agent-repo.sh --also-install

# Step 7: Install unzip
sudo yum makecache
sudo yum install -y unzip

echo "Initialization completed."