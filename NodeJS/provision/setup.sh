#!/bin/bash

echo "*******************************" 
echo "Provisioning virtual machine..."
echo "*******************************" 


echo "***********************"
echo "Updating apt sources..."
echo "***********************"
sudo apt-get -qq update


echo "***********************************"
echo "Install and re-link node and npm..."
echo "***********************************"
sudo apt-get -y -qq install build-essential nodejs npm redis-server
sudo npm install -g forever
sudo ln -s "$(which nodejs)" /usr/bin/node


echo "***********************************"
echo "Run npm install and then run app..."
echo "***********************************"
cd sample-app
sudo npm install
sudo forever start server.js


echo "*********************************"
echo "Success! Navigate to localhost..."
echo "*********************************"
