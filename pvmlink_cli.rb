#!/usr/bin/env ruby

$LOAD_PATH.unshift File.expand_path( File.join File.dirname(__FILE__),"")

require "rubygems"
require "pp"
require "optparse"
require "pvmhost"

opt = OptionParser.new

opts = {}

def usage_and_exit(code = 1)
  puts "USAGE: tenv pvmlink list"
  puts "            pvmlink create --pvm <pvm name> --on <pvmhost name> [--ipaddress <ipaddress> --prefix <prefix>] --ovs <open vswitch name> --tag <tag vlan id>"
  puts "            pvmlink delete --pvm <pvm name> --on <pvmhost name> --dev <dev name> --ovs <open vswitch name>"
  exit code
end

unless ARGV[0] == "list"   || ARGV[0] == "create" ||
       ARGV[0] == "delete"
  usage_and_exit
end

opt.on("--pvm VAL") do |name|
  opts[:pvm] = name
end
opt.on("--on VAL") do |name|
  opts[:on] = name
end
opt.on("--ipaddress VAL") do |name|
  opts[:ip_address] = name
end
opt.on("--prefix VAL") do |name|
  opts[:prefix] = name
end
opt.on("--ovs VAL") do |name|
  opts[:ovs] = name
end
opt.on("--dev VAL") do |name|
  opts[:dev] = name
end
opt.on("--tag VAL") do |name|
  opts[:tag] = name
end

opt.parse(ARGV)

if ARGV[0] == "list"
  template = "%11s|%8s|%8s|%15s|%4s|%7s|%17s\n"
  printf(template,"pvm","dev","ldev","ip address","vlan","sw","mac")
  PVmhost.alived_hosts.each do |pvmhost|
    next if pvmhost.local?
    pvmhost.pvms.each do |pvm|
      pvm.network_interfaces.each do |nif|
        printf(template, 
               pvm.name, 
               nif.name, 
               PVmhost::ns_to_br(nif.name),
               nif.ip_address, 
               "    ", 
               nif.ovs, 
               nif.mac)
      end
    end
  end
elsif ARGV[0] == "create"
  pvmhost = PVmhost.all.detect{|a| a.name == opts[:on]}
  unless pvmhost
    puts "ERROR: no such pvmhost: #{opts[:on]}"
    exit 1
  end
  pvmhost.create_pvm_link(:pvm_name => opts[:pvm],
                          :ovs_name => opts[:ovs],
                          :ip_address => opts[:ip_address],
                          :prefix => opts[:prefix],
                          :tag => opts[:tag])
elsif ARGV[0] == "delete"
  pvmhost = PVmhost.all.detect{|a| a.name == opts[:on]}
  unless pvmhost
    puts "ERROR: no such pvmhost: #{opts[:on]}"
    exit 1
  end
  pvmhost.delete_pvm_link(:pvm_name => opts[:pvm],
                          :dev => opts[:dev],
                          :ovs => opts[:ovs])  
end

