##!/bin/bash
echo "Downloading RVM..."
curl -sSL https://rvm.io/mpapis.asc | gpg --import -
curl -L get.rvm.io | bash -s stable
source /etc/profile.d/rvm.sh
echo "Reloading RVM..."
rvm reload
echo "Installing RVM dependencies..."
rvm requirements run
echo "Downloading JRuby 9.0.3.0..."
rvm install jruby-9.0.0.0
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
sudo ln -s  ~/collector/collector.sh /usr/bin/collector
echo "Installation complete. Please reboot your system."
