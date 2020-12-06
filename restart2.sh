set -x
sudo ./pvm_cli.rb delete --name pvm1 --on localhost
sudo ./pvm_cli.rb delete --name pvm2 --on localhost
sudo ./sw_cli.rb  delete --name 10_0_0_0

sudo ./sw_cli.rb list
sudo ./pvm_cli.rb list

sudo ./sw_cli.rb  create --subnet 10.0.0.0 --prefix 24
sudo ./pvm_cli.rb create --name pvm1 --on localhost
sudo ./pvm_cli.rb create --name pvm2 --on localhost
sudo ./sw_cli.rb list
sudo ./pvm_cli.rb list

sudo ./pvmlink_cli.rb create --pvm pvm1 --on localhost --ovs 10_0_0_0 --tag 1 --ipaddress 10.0.0.10 --prefix 24
sudo ./pvmlink_cli.rb create --pvm pvm2 --on localhost --ovs 10_0_0_0 --tag 1 --ipaddress 10.0.0.11 --prefix 24

#sudo byebug ./pvmlink_cli.rb create --pvm pvm1 --on localhost --ovs 10_0_0_0 

