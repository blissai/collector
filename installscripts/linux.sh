##!/bin/bash

if [[ -n "$(command -v yum)" ]]
then
if [[ ! -n "$(command -v rvm)" ]]
  then
  echo "RVM not installed. Installing..."
  yum install -y gcc-c++ patch readline readline-devel zlib zlib-devel
  yum install -y libyaml-devel libffi-devel openssl-devel make
  yum install -y bzip2 autoconf automake libtool bison iconv-devel
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
if [[ ! -n "$(command -v npm)" ]]
then
  echo "Node not installed. Installing..."
  curl -sL https://rpm.nodesource.com/setup | bash -
  sudo yum -y install nodejs
  sudo yum -y install gcc-c++ make
fi
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
if [[ ! -n "$(command -v npm)" ]]
then
  echo "Node not installed. Installing..."
  sudo apt-get -y install nodejs npm
  sudo apt-get -y install gcc-c++ make
fi
fi
echo "Downloading Ruby 2.x..."
rvm install 2.2.2
echo "Setting Ruby version to 2.x..."
rvm use 2.2.2 --default
rvm reload
git clone https://github.com/founderbliss/collector.git ~/collector
sudo chmod +x ~/collector/collector.sh
sudo ln -s  ~/collector/collector.sh /usr/bin/collector
sudo ln -s  ~/collector/blissauto.sh /usr/bin/autocollector
echo "Installation complete. Please reboot your system."
