##!/bin/bash
echo "Downloading RVM..."
if [[ ! -n "$(command -v rvm)" ]]
then
  echo "RVM not installed. Please make sure RVM and Homebrew are installed before proceeding."
elif [[ ! -n "$(command -v brew)" ]]
then
  echo "Homebrew not installed. Please make sure RVM and Homebrew are installed before proceeding."
else
  echo "Downloading JRuby 9.0.3.0..."
  rvm install jruby-9.0.3.0
  echo "Setting Ruby version to JRuby-9.0.3.0..."
  rvm use jruby-9.0.3.0 --default
  rvm reload
  if [[ ! -n "$(command -v npm)" ]]
    then
    echo "Node not installed. Installing..."
    brew install nodejs
  fi
  git clone https://github.com/founderbliss/collector.git ~/collector
  sudo chmod +x ~/collector/collector.sh
# sudo ln -s  ~/collector/collector.sh /usr/bin/collector
  echo "Installation complete. Please reboot your system."
fi
