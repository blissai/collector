##!/bin/bash
if [[ -n "$(command -v yum)" ]]
then
  sudo rpm --import https://rpm.packager.io/key
  echo -e "[collector]\n
  name=Repository for founderbliss/collector application.\n
  baseurl=https://rpm.packager.io/gh/founderbliss/collector/centos6/master\n
  enabled=1" | sudo tee /etc/yum.repos.d/collector.repo
  sudo yum install collector
elif [[ -n "$(command -v apt-get)" ]]
then
  wget -qO - https://deb.packager.io/key | sudo apt-key add -
  echo "deb https://deb.packager.io/gh/founderbliss/collector wheezy master" | sudo tee /etc/apt/sources.list.d/collector.list
  sudo apt-get update
  sudo apt-get install collector
fi
