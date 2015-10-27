#!/usr/bin/env bash
if [[ -n "$(command -v apt-get)" ]]
then
  apt-get -y update
  apt-get -y install build-essential zlib1g-dev libssl-dev libreadline6-dev libyaml-dev
  cd /tmp
  wget http://ftp.ruby-lang.org/pub/ruby/2.1/ruby-2.1.5.tar.gz
  tar -xvzf ruby-2.1.5.tar.gz
  cd ruby-2.1.5/
  ./configure --prefix=/usr/local
  sudo make
  sudo make install
  sudo apt-get install php5-cli
  sudo apt-get install nodejs
fi

if [[ -n "$(command -v yum)" ]]
then
  sudo yum install ruby
  sudo yum install php55w php55w-opcache
  sudo yum install nodejs
fi
