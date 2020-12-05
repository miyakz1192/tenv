
require "tenv_config"


class Log
  def self.info(str)
    puts str
  end
end

class IPAddr
  def subnet_mask
    return IPAddr.new(@mask_addr, @family)
  end

  def network_mask
    subnet_mask
  end

  def proceed
    return self.clone.set(@addr - 1, @family)
  end

  def to_host_range
    (to_range.first.succ)..(to_range.last.proceed)
  end
end

class NetworkInterface
  attr_accessor :name, :ip_address, :mac, :ovs
  #interface name(string)
  #ip_address (string)
  #mac address(string)
  #ovs (open vswitch name) string
  def initialize(ifname, ip_address, mac, ovs)
    @name = ifname
    @ip_address = ip_address
    @mac = mac
    @ovs = ovs
  end
end

class NetworkNameSpace
  attr_reader :name

  def initialize(name, host = PVmhost.localhost)
    @name = name
    @host = host
  end

  def exec_root(cmd)
    @host.exec_root(cmd)
  end

  def delete
    network_interfaces.each do |nif|
      @host.delete_pvm_link(:pvm_name => @name,
                            :dev => nif.name,
                            :ovs => nif.ovs)
    end
    exec_root("ip netns delete #{name}")
  end

  def netdevs
    exec_root("ip netns exec #{name} ifconfig -a | grep ether | awk '{print $1}'").split("\n")
  end

  def ovs_daemon_boot?
    exec_root("pgrep ovs-vswitchd").size != 0
  end

  def network_interfaces
    netif = []
    is_ovs_booted = ovs_daemon_boot? 

    cmd_res = exec_root("ip netns exec #{name} ifconfig -a")
    _temp_cmd_res = cmd_res.split("\n")

    cmd_res.split("\n").each_with_index do |info, index|
      info.strip!
      next unless info =~ /ether/
      
      #hit new network interface info
      name = info.split[0]
      mac = info.split("ether")[1].strip
      ip = "" #default value is void string

      #ip address is next line
      if _temp_cmd_res[index + 1] =~ /inet addr/
        ip = _temp_cmd_res[index + 1].split("inet addr:")[1].split[0]
      end

      ovs = ""
      if is_ovs_booted
        ovs = exec_root("ovs-vsctl port-to-br #{PVmhost.ns_to_br(name)} 2> /dev/null")
        ovs.strip!
      end

      netif << NetworkInterface.new(name, ip, mac, ovs)
    end
    return netif
  end

  def self.all(host = PVmhost.localhost)
    res = []
    host.exec_root("ip netns").split("\n").each do |netns|
      res << NetworkNameSpace.new(netns, host)
    end
    return res
  end
end

class TEnv
  include TEnvConfig
  DATA_PATH="/home/miyakz/tenv"
  UNIQ_NETDEV_PREFIX = "tenv_n_"

  @@tenv_path  = File.expand_path(File.dirname(__FILE__))
  @@tenv_data_path = @@tenv_path + "/data"

protected

  def _cmd(str)
    Log.info(str)
    `#{str}`
  end

  def cmd(str)
    Log.info(str)
    `#{str}`
    raise "ERROR at #{str}" if $? != 0
    Log.info("#{str} => #{$?}")
  end

  def cmd_retry(str)
    for i in 1..10
      Log.info(str)
      `#{str}`
      break if $? == 0
      Log.info("#{str} RETRY! sleep 1 sec...")
      sleep 1
    end
  end

  def get_netdevs_in_system(host = PVmhost.localhost)
    devs = host.exec_root('ifconfig -a | grep ether | awk \'{print $1}\'').split("\n")
    NetworkNameSpace.all(host).each do |netns|
      devs << netns.netdevs
    end
    return devs.flatten.uniq # like a "lo"
  end

  def get_uniq_devname_pair(prefix, host = PVmhost.localhost)
    devs = get_netdevs_in_system(host)
    dev0 = get_uniq_devname(devs         , prefix)
    dev1 = get_uniq_devname(devs << dev0 , prefix)
    return [dev0 ,dev1]
  end

  def get_uniq_devname(devs, prefix)
    c = 0
    while 1      
      unless devs.detect{|d| d == "#{prefix}#{c}"}
        return "#{prefix}#{c}" 
      end
      c += 1
    end
  end
end
