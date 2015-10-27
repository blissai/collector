echo "Downloading RVM..."
curl -sSL https://rvm.io/mpapis.asc | gpg --import -
curl -L get.rvm.io | bash -s stable
echo "Installing RVM..."
source /etc/profile.d/rvm.sh
echo "Reloading RVM..."
rvm reload
echo "Installing RVM dependencies..."
rvm requirements run
echo "Download Ruby 2.x..."
rvm install 2.0.0
echo "Setting Ruby version to 2.x..."
rvm use 2.0.0 --default
