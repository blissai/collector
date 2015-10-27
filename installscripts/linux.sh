##!/bin/bash

if [[ -n "$(command -v yum)" ]]
then
if [[ ! -n "$(command -v rvm)" ]]
  then
  echo "RVM not installed. Installing..."
  yum install gcc-c++ patch readline readline-devel zlib zlib-devel
  yum install libyaml-devel libffi-devel openssl-devel make
  yum install bzip2 autoconf automake libtool bison iconv-devel
  echo "Downloading RVM..."
  curl -sSL https://rvm.io/mpapis.asc | gpg --import -
  curl -L get.rvm.io | bash -s stable
  echo "Installing RVM..."
  source /etc/profile.d/rvm.sh
  echo "Reloading RVM..."
  rvm reload
  echo "Installing RVM dependencies..."
  rvm requirements run
fi
echo "Download Ruby 2.x..."
rvm install 2.0.0
echo "Setting Ruby version to 2.x..."
rvm use 2.0.0 --default
if [[ ! -n "$(command -v npm)" ]]
then
  echo "Node not installed. Installing..."
  sudo yum -y install nodejs --enablerepo=epel
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
if [[ ! -n "$(command -v rvm)" ]]
then
  echo "RVM not installed. Installing..."
  sudo apt-add-repository -y ppa:rael-gc/rvm
  sudo apt-get update
  sudo apt-get -y install rvm
  # sudo apt-get -y install gcc-c++ patch readline readline-devel zlib zlib-devel libyaml-devel libffi-devel openssl-devel make bzip2 autoconf automake libtool bison iconv-devel
  rvm reload
  rvm requirements run
fi
rvm install 2.0.0
rvm use 2.0.0 --default
if [[ ! -n "$(command -v npm)" ]]
then
  echo "Node not installed. Installing..."
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
echo "Installation complete."
