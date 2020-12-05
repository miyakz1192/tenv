# -*- coding: euc-jp -*-
require "common"
require "ipaddr"
require 'rubygems'
require 'net/ssh'
require 'pty'
require 'expect'
require 'pvm'
require 'command_executer'

class PVmhostView 
  def self.list
    template = "%10s|%15s|%17s\n"
    printf(template, "pvmhost", "sw", "ip address")
    pvmhosts = PVmhost.all
    PVmhost.check_alive(pvmhosts)
    pvmhosts.each do |pvmhost|
      if pvmhost.alived
        name = pvmhost.name
      else
        name = "?#{pvmhost.name}"
      end
      printf(template, name, pvmhost.sw, pvmhost.ip_address)
    end
  end 
end

class PVmhost < TEnv
  attr_accessor :name, :sw, :alived, :ip_address #without prefix

  UNIQ_PVM_PREFIX = "tenv_ns_"

  def initialize(params = {})
    @name = params[:name]
    @sw   = params[:sw]
    @ip_address = params[:ip_address]
    @cmdexec = CommandExecuter.create(@ip_address)
  end

protected
  
public

  def self.localhost
    return PVmhost.new(:name => "localhost",
                       :ip_address => "127.0.0.1",
                       :sw => "none")
  end

  def self.all
    res = [PVmhost.localhost]
    `ls #{@@tenv_data_path}`.split("\n").each do |br|
      br.strip!
      `cat #{@@tenv_data_path}/#{br}/lease`.split("\n").each do |l|
        temp = l.split
        pvmhost = temp[3]
        ip      = temp[2]
        res << PVmhost.new(:name => pvmhost, :sw => br, :ip_address => ip)
      end
    end
    return res
  end

  def self.alived_hosts
    vmhosts = self.all
    self.check_alive(vmhosts)
    return vmhosts.select{|a| a.alived?}
  end

  def self.check_alive(pvmhosts)
    threads = []
    pvmhosts.each do |pvmhost|
      threads << Thread.new do
        pvmhost.alive?
      end
    end
    threads.each {|t| t.join}
  end

  def self.normalize_all_name
    puts "normalize all name"
    raise "this method must returns pvm's on this"
  end

  def alived?
    return alive?
  end

  def alive?()
    @alived = false
    return false unless @ip_address
    `ping #{@ip_address} -c 1 -W 1`
    if $? == 0
      @alived = true
      return true
    end
    return false
  end

  def local?
    return @ip_address == "127.0.0.1"
  end

  def rename(new_name)
    #TODO: make a redhat and etc ...
    #this version is ubuntu only

    exec("mkdir /tmp/tenv")
    upload("#{@@tenv_path}/*.rb", "/tmp/tenv")
    exec_root("/tmp/tenv/renamehostname.rb #{new_name}")
    exec_root("hostname #{new_name}")
    @name = new_name
  end

  def exec(command, opts = {})
    return @cmdexec.exec(command, opts)
  end

  def exec_root(cmd)
    exec(cmd, :root => true)
  end
  
  #http://takuya-1st.hatenablog.jp/entry/20110919/1316426672
  def scp(local, remote, opts = {})
    return @cmdexec.scp(local, remote, opts)
  end

  def upload(local, remote)
    scp(local, remote, :upload => true)
  end

  def pvms
    PVm.all(self)
  end

  def create_pvm(name = nil)
    if name
      new_pvm_name = name
    else
      new_pvm_name = get_uniq_devname(pvms.map{|a| a.name}, 
                                      "#{UNIQ_PVM_PREFIX}")
    end

    exec_root("ip netns add #{new_pvm_name}")
  end

  def delete_pvm(name = nil)
    if name
      PVm.new(name, self).delete
    else
      pvms.each do |netns|
        exec_root("ip netns delete #{netns.name}")
      end
    end
  end
  
  def self.ns_to_br(dev_ns)
    dev_br_index = dev_ns.split("#{UNIQ_NETDEV_PREFIX}")[1].to_i + 1
    return "#{UNIQ_NETDEV_PREFIX}#{dev_br_index}"
  end

  #=== create pvm link to ovs
  #_params[:pvm_name]_ :: pvm name
  #_params[:ovs_name]_ :: ovs name that is connected from pvm
  #_params[:tag]_ :: tag vlan id(for GRE only)
  #_params[:ip_address]_ :: ip address
  #_params[:prefix]_ :: prefix
  def create_pvm_link(params = {})
    pvm_name = params[:pvm_name]
    ovs_name = params[:ovs_name]
    tag = params[:tag]

    ip = nil
    if params[:ip_address] && params[:prefix]
      ip = "#{params[:ip_address]}/#{params[:prefix]}"
    end

    unless pvms.detect{|a| a.name == pvm_name}
      raise "ERROR: no such pvm #{pvmname}" 
    end
    dev_ns, dev_br = get_uniq_devname_pair("#{UNIQ_NETDEV_PREFIX}", self)
    exec_root("ip link add name #{dev_br} type veth peer name #{dev_ns}")
    exec_root("ovs-vsctl add-port #{ovs_name} #{dev_br} tag=#{tag}")
    exec_root("ifconfig #{dev_br} up")
    exec_root("ifconfig #{dev_ns} up")
    exec_root("ip link set dev #{dev_ns} netns #{pvm_name}")
    if ip
      exec_root("ip netns exec #{pvm_name} ifconfig #{dev_ns} #{ip}")
    end
    sleep 1
    mac = exec_root("ip netns exec #{pvm_name} ifconfig -a | grep #{dev_ns} | awk -F HWaddr '{print $2}'").strip
    create_logical_attachment(:ovs_name => ovs_name,
                              :devname => dev_br,
                              :iface_id => dev_br,
                              :vm_uuid => pvm_name,
                              :mac => mac)
  end

  #=== delete pvm link
  #_params[:pvm_nane]_ :: pvm name
  #_params[:dev]_ :: network device name on pvm
  #_params[:ovs]_ :: open vswitch name
  def delete_pvm_link(params = {})
    dev_ns = params[:dev]
    dev_br = PVmhost::ns_to_br(dev_ns)

    exec_root("ovs-vsctl del-port #{params[:ovs]} #{dev_br}")
    exec_root("ip netns exec #{params[:pvm_name]} ifconfig #{dev_ns} down")
    exec_root("ip link del #{dev_br}")
  end

  #=== create logical attachment to ovs
  #_params[:ovs_name]_ :: ovs name
  #_params[:devname]_ :: device name that is connected to ovs
  #_params[:iface_id]_ :: logical interface id 
  #_params[:vm_uuid]_ :: vm uuid
  #_params[:mac]_ :: mac address of devname
  def create_logical_attachment(params = {})
    cmd = "ovs-vsctl -- --may-exist add-port #{params[:ovs_name]} #{params[:devname]} -- set Interface #{params[:devname]} external-ids:iface-id=#{params[:iface_id]} external-ids:iface-status=active external-ids:attached-mac=#{params[:mac]} external-ids:vm-uuid=#{params[:vm_uuid]}"
    puts exec_root(cmd)
  end
end


#res = PVmhost.new("192.168.1.161").exec("reboot", :root => true)
#pvmhost = PVmhost.new("192.168.1.161")
#pvmhost.exec("mkdir /tmp/tenv")
#pvmhost.upload("*.rb", "/tmp/tenv")
#puts pvmhost.rename("vmhost1")
#puts pvmhost.exec_root("whoami")
#pvmhost.exec("chmod 766 /tmp/tenv/*")
#puts res

