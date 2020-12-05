#!/usr/bin/env ruby

$LOAD_PATH.unshift File.expand_path( File.join File.dirname(__FILE__),"")

require "bridge"
require "rubygems"
require "rest-client"
require "pp"
require "optparse"

opt = OptionParser.new

opts = {}

def usage_and_exit(code = 1)
  puts "USAGE: tenv sw list"
  puts "            sw create --name <sw name> --dhcpip <ip> --swip <ip> --prefix <prefix length> --range <ip range> [--type ovs|normal]"
  puts "            sw create --subnet <subnet address> --prefix <prefix length> [--type ovs|normal]"
  puts "            sw delete --name <sw name>"
  exit code
end

unless ARGV[0] == "list"   || ARGV[0] == "create" ||
       ARGV[0] == "delete"
  usage_and_exit
end

if ARGV[0] == "create" || ARGV[0] == "delete"
  opt.on("--name VAL") do |name|
    opts[:name] = name
  end
  opt.on("--dhcpip VAL") do |name|
    opts[:dhcpip] = name
  end
  opt.on("--swip VAL") do |name|
    opts[:swip] = name
  end
  opt.on("--prefix VAL") do |name|
    opts[:prefix] = name
  end
  opt.on("--range VAL") do |name|
    opts[:range] = name
  end
  opt.on("--subnet VAL") do |name|
    opts[:subnet] = name
  end
  opt.on("--type VAL") do |name|
    opts[:type] = name
  end
end

opt.parse(ARGV)

if ARGV[0] == "list"
  Bridge.list
elsif ARGV[0] == "create"
  Bridge.new(opts).setup
elsif ARGV[0] == "delete"
  Bridge.new(opts).unsetup
end
