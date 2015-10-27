##!/bin/bash

if [[ -n "$(command -v yum)" ]]
then
if [[ ! -n "$(command -v npm)" ]]
  then
  sudo yum -y install nodejs
  sudo yum -y install gcc-c++ make
fi
sudo rpm --import https://rpm.packager.io/key
echo "[collector]
name=Repository for founderbliss/collector application.
baseurl=https://rpm.packager.io/gh/founderbliss/collector/centos6/master
enabled=1" | sudo tee /etc/yum.repos.d/collector.repo
sudo yum -y install collector
elif [[ -n "$(command -v apt-get)" ]]
then
if [[ ! -n "$(command -v npm)" ]]
  then
  sudo yum -y install nodejs npm
  sudo yum -y install gcc-c++ make
fi
wget -qO - https://deb.packager.io/key | sudo apt-key add -
echo "deb https://deb.packager.io/gh/founderbliss/collector wheezy master" | sudo tee /etc/apt/sources.list.d/collector.list
sudo apt-get update
sudo apt-get -y install collector
fi
sudo chmod +x /opt/collector/collector.sh
ln -s /opt/collector/collector.sh /usr/bin/collector
