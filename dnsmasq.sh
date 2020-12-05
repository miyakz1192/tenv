#!/bin/bash

if [ $# -ne 4 ]; then
    echo "usage: dnsmasq dev range data_path uuid"
    exit 1
fi

echo $0

dev=$1
range=$2
data_path=$3
uuid=$4

echo "dev       = ${dev}"
echo "range     = ${range}"
echo "data_path = ${data_path}"
echo "uuid      = ${uuid}"

mkdir -p ${data_path}/${uuid} >& /dev/null
touch ${data_path}/${uuid}/pid >& /dev/null

cmd="dnsmasq --no-hosts --no-resolv --strict-order --bind-interfaces --interface=${dev} --except-interface=lo --pid-file=${data_path}/${uuid}/pid --dhcp-hostsfile=${data_path}/${uuid}/host --dhcp-leasefile=${data_path}/${uuid}/lease --dhcp-range=set:tag0,${range},infinite"

#cmd="dnsmasq --no-hosts --no-resolv --strict-order --bind-interfaces --interface=${dev} --except-interface=lo --pid-file=${data_path}/${uuid}/pid --dhcp-hostsfile=${data_path}/${uuid}/host --dhcp-leasefile=${data_path}/${uuid}/lease --dhcp-range=192.168.1.0,static,120m"

#cmd="dnsmasq --no-hosts --no-resolv --strict-order --bind-interfaces --interface=${dev} --except-interface=lo --pid-file=${data_path}/${uuid}/pid --dhcp-leasefile=${data_path}/${uuid}/lease --dhcp-range=192.168.1.0,static,120m"

echo ${cmd}

# sudo is needed. because nobody can not read files that root made.
`sudo ${cmd}`



