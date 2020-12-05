
require "common"

class BridgeOperator < TEnv
  def self.create(type)
    type.downcase! if type
    puts "type=#{type}"
    begin
      #upcase type's first
      class_name="#{type[0, 1].to_s.upcase}#{type[1, type.size]}BridgeOperator"
      puts "#{class_name}"
      return Kernel.const_get(class_name).new
    rescue
      return NormalBridgeOperator.new
    end
  end
end

class OvsBridgeOperator < BridgeOperator
  def add_bridge(name)
    cmd_retry "ovs-vsctl add-br #{name}"
  end
  
  def delete_bridge(name)
    _cmd "ovs-vsctl del-br #{name}"
  end

  def add_interface(br_name, if_name)
    cmd "ovs-vsctl add-port #{br_name} #{if_name}"
  end
end

class NormalBridgeOperator < BridgeOperator
  def add_bridge(name)
    cmd_retry "brctl addbr #{name}"
  end
  
  def delete_bridge(name)
    _cmd "brctl delbr #{name}"
  end

  def add_interface(br_name, if_name)
    cmd "brctl addif #{br_name} #{if_name}"
  end
end
