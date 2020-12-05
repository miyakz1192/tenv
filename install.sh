set -x

echo "install packaged for ruby setup"
sudo apt update
sudo apt install ruby -y
sudo apt install ruby-dev -y
sudo apt install gcc -y
sudo apt install make -y
sudo apt install g++ -y

echo "install ifconfig"
sudo apt install net-tools

echo "install openvswitch"
sudo apt install openvswitch-switch -y
sudo apt install openvswitch-common  -y

echo "install dnsmasq"
sudo apt install dnsmasq -y

echo "install related gem packages"
sudo gem install net-ssh
sudo gem install rest-client
sudo gem install byebug

