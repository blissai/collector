##!/bin/bash

if [[ -n "$(command -v yum)" ]]
then
if [[ ! -n "$(command -v rvm)" ]]
  then
  echo "RVM not installed. Installing..."
  sudo yum install -y gcc-c++ patch readline readline-devel zlib zlib-devel
  sudo yum install -y libyaml-devel libffi-devel openssl-devel make
  sudo yum install -y bzip2 autoconf automake libtool bison iconv-devel
  echo "Downloading and Installing RVM..."
  curl -sSL https://rvm.io/mpapis.asc | gpg --import -
  curl -L get.rvm.io | bash -s stable --ruby=jruby-9.0.3.0 --gems=bundler
  source ~/.rvm/scripts/rvm
fi
if [[ ! -n "$(command -v npm)" ]]
then
  echo "Node not installed. Installing..."
  sudo curl --silent --location https://rpm.nodesource.com/setup | bash -
  sudo yum install -y nodejs --enablerepo=epel
  sudo yum -y install gcc-c++ make
fi
sudo yum install -y git php
elif [[ -n "$(command -v apt-get)" ]]
then
if [[ ! -n "$(command -v rvm)" ]]
then
  echo "RVM not installed. Installing..."
  echo "Downloading and Installing RVM..."
  curl -sSL https://rvm.io/mpapis.asc | gpg --import -
  curl -L get.rvm.io | bash -s stable --ruby=jruby-9.0.3.0 --gems=bundler
fi
if [[ ! -n "$(command -v npm)" ]]
then
  echo "Node not installed. Installing..."
  sudo apt-get -y install nodejs npm
  sudo apt-get -y install gcc-c++ make
fi
sudo apt-get -y install git php
fi
# echo "Downloading JRuby 9.0.3.0..."
# rvm install jruby-9.0.3.0
# echo "Setting Ruby version to JRuby-9.0.3.0..."
# rvm use jruby-9.0.3.0 --default
# rvm reload

# sudo ln -s  ~/collector/collector.sh /usr/bin/collector
echo "Installation complete. Please reboot your system."
