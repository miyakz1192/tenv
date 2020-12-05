#!/usr/bin/env ruby

$LOAD_PATH.unshift File.expand_path( File.join File.dirname(__FILE__),"")

require "pvm"
require "rubygems"
require "pp"
require "optparse"

opt = OptionParser.new

opts = {}

def usage_and_exit(code = 1)
  puts "USAGE: tenv pvm list"
  puts "            pvm create [--name <name>] --on <pvmhost name>"
  puts "            pvm delete [--name <name>] --on <pvmhost name>"
  exit code
end

unless ARGV[0] == "list"   || ARGV[0] == "create" ||
       ARGV[0] == "delete"
  usage_and_exit
end

opt.on("--name VAL") do |name|
  opts[:name] = name
end
opt.on("--on VAL") do |name|
  opts[:on] = name
end

opt.parse(ARGV)

if ARGV[0] == "list"
  PVmView.list
elsif ARGV[0] == "create" || ARGV[0] == "delete"
  pvmhost = PVmhost.alived_hosts.detect{|a| a.name == opts[:on]}
  unless pvmhost
    puts "no such pvmhost #{opts[:on]}"
    exit 1
  end
  if ARGV[0] == "create"
    pvmhost.create_pvm(opts[:name])
  elsif ARGV[0] == "delete"
    pvmhost.delete_pvm(opts[:name])
  end
end
