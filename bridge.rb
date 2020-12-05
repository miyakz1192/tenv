#!/usr/bin/env ruby

#$LOAD_PATH.unshift File.expand_path( File.join File.dirname( __FILE__ ),"")

require "common"
require "ipaddr"
require "pvmhost"
require "bridge_operator"

class Bridge < TEnv
  attr_accessor :name, :swip, :dhcpip, :prefix
protected
  def make_bridge
    puts "=== make_bridge ==="
    `ifconfig #{name} 1> /dev/null 2> /dev/null`
    if $? == 0
      puts "INFO: already exists #{name}. skip make bridge operation"
      return
    end
    @br_ope.add_bridge(name)
#    cmd_retry "brctl addbr #{name}"
  end
  
  def make_ns_with_bridge_name
    puts "=== make_ns_with_bridge_name === "
    `ip netns | grep -x #{name} 2> /dev/null`
    if $? == 0
      puts "INFO: already exists #{name}. skip make NS operation"
      return
    end
    cmd_retry "ip netns add #{name}"
  end

  def connect_ns_to_bridge
    dev_br, dev_ns = get_uniq_devname_pair(UNIQ_NETDEV_PREFIX)
    puts "TRACE: uniq devname pair #{dev_br} #{dev_ns}"
    cmd "ip link add name #{dev_br} type veth peer name #{dev_ns}"
    cmd "ip link set dev #{dev_ns} netns #{@name}"
    @br_ope.add_interface(name, dev_br)
#    cmd "brctl addif #{@name} #{dev_br}"
    cmd "ip netns exec #{@name} ifconfig #{dev_ns} #{@dhcpip.to_s}/#{@prefix} up"
    cmd "ifconfig #{@name} #{@swip}/#{@prefix} up"
    cmd "ifconfig #{dev_br} up"
    return dev_ns # return ns side network device name
  end

  def run_dnsmasq(dev_name)
    subnet_mask = IPAddr.new("#{@dhcpip}/#{@prefix}")
    c = "ip netns exec #{name} #{@@tenv_path}/dnsmasq.sh #{dev_name} #{@range} #{@@tenv_data_path} #{name}"
    puts c
    `#{c}`
  end

public
  #==== initialize
  #_params[:subnet]_ :: subnet address(string)
  #_params[:prefix]_ :: prefix length(string)
  #_params[:type]_ :: bridge type(string)
  # or 
  #_params[:dhcpip]_ :: dhcp side ip address(string)
  #_params[:swip]_ :: switch side ip address(string)
  #_params[:prefix]_ :: prefix length(string)
  #_params[:name]_ :: switch name(string)
  #_params[:range]_ :: ip range(string) ex) 192.168.1.1,192.168.1.240
  def initialize(params={})
    puts "=== initialize ==="
    @prefix = params[:prefix]
    @type = params[:type]

    @br_ope = BridgeOperator.create(@type)

    if params[:subnet].nil?
      @dhcpip = params[:dhcpip]
      @swip   = params[:swip]
      @name   = params[:name]
      @range  = params[:range]
    else
      subnet = IPAddr.new("#{params[:subnet]}/#{@prefix}")
      swip_ipaddr = subnet.to_host_range.last.proceed
      @dhcpip = subnet.to_host_range.last
      @swip   = swip_ipaddr.to_s
      @name   = params[:subnet].gsub(/\./, "_")
      @range  = "#{subnet.to_host_range.first},#{swip_ipaddr.proceed}"
    end
  end

  def setup
    puts "=== setup ==="
    begin
      make_bridge
      make_ns_with_bridge_name
      ns_dev_name = connect_ns_to_bridge    
      run_dnsmasq(ns_dev_name)
    rescue => e
      puts "ERROR !!! rollback!!!"
      puts e.message
      puts e.backtrace
      unsetup
    end
  end

  def unsetup
    devs = NetworkNameSpace.new(@name).netdevs
    _cmd "kill \`cat #{@@tenv_data_path}/#{@name}/pid | tr -d \"\\n\"\`"
    puts devs.inspect
    devs.each do |dev|
      _cmd "ip netns exec #{@name} ip link delete #{dev}"
    end
    _cmd "ip netns delete #{@name}"
    _cmd "ifconfig #{@name} down"

    @br_ope.delete_bridge(name)
#    _cmd "brctl delbr #{@name}"
    _cmd "rm -rf #{@@tenv_data_path}/#{@name}/ 1> /dev/null 2> /dev/null"
  end

  def self.list
    template = "%10s|%17s|%5s\n"
    printf(template, "name", "ip/prefix", "hosts")
    `ls #{@@tenv_data_path}`.split("\n").each do |br|
      br.strip!
      `ifconfig #{br} 1> /dev/null 2> /dev/null`
      if $? == 0
        ip = `ip netns exec #{br} ip addr 2> /dev/null| grep "inet " | awk '{print $2}'`.strip
        hosts = `cat #{@@tenv_data_path}/#{br}/lease | wc -l`.strip.to_i
        printf(template, br, ip, hosts)
      else
        printf(template, "!#{br}", ip, "0")
      end
    end
  end
end

#Bridge.new(ARGV[0], ARGV[1]).unsetup
#Bridge.new(ARGV[0], ARGV[1]).setup
#puts NetworkNameSpace.new("intbr").netdevs.inspect
