#!/usr/bin/env ruby

$LOAD_PATH.unshift File.expand_path( File.join File.dirname(__FILE__),"")

require "pvmhost"
require "rubygems"
require "pp"
require "optparse"

opt = OptionParser.new

opts = {}

def usage_and_exit(code = 1)
  puts "USAGE: tenv pvmhost list"
  puts "            pvmhost rename --ipaddress <ip> --name <new name>"
  puts "            pvmhost rename --normalize"
  puts "            pvmhost reboot {--ipaddress <ip>|--name <host name>}"
  puts "            pvmhost halt   --ipaddress <ip>"
  puts "            pvmhost ping   --ipaddress <ip>"
  exit code
end

unless ARGV[0] == "list"   || ARGV[0] == "rename" ||
       ARGV[0] == "normalize" || ARGV[0] == "reboot"  ||
       ARGV[0] == "ping"
  usage_and_exit
end

if ARGV[0] == "rename" || ARGV[0] == "reboot" || ARGV[0] == "ping"
  opt.on("--name VAL") do |name|
    opts[:name] = name
  end
  opt.on("--ipaddress VAL") do |name|
    opts[:ipaddress] = name
  end
  opt.on("--normalize VAL") do |name|
    opts[:normalize] = true
  end
end

opt.parse(ARGV)

if ARGV[0] == "list"
  PVmhostView.list
elsif ARGV[0] == "rename"
  pvmhost = PVmhost.new(:ip_address => opts[:ipaddress])
  pvmhost.rename(opts[:name])
elsif ARGV[0] == "delete"
  PVmhost.normalize_all_name
elsif ARGV[0] == "reboot"
  if opts[:ipaddress]
    pvmhost = PVmhost.new(:ip_address => opts[:ipaddress])
  elsif opts[:name]
    pvmhost = PVmhost.alived_hosts.detect{|a| a.name == opts[:name]}
  end
  pvmhost.exec_root("reboot")
elsif ARGV[0] == "halt"
  pvmhost = PVmhost.new(:ip_address => opts[:ipaddress])
  pvmhost.exec_root("halt")  
elsif ARGV[0] == "ping"
  pvmhost = PVmhost.new(:ip_address => opts[:ipaddress])
  puts pvmhost.alive?
end
