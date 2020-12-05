# -*- coding: euc-jp -*-
require "common"
require "ipaddr"
require 'rubygems'
require 'net/ssh'
require 'pty'
require 'expect'
require 'pvmhost'

class PVmView 
  def self.list
    template = "%15s|%15s|%17s\n"
    printf(template, "pvm", "pvmhost", "pvmhost ip")
    PVmhost.alived_hosts.each do |host|
      host.pvms.each do |pvm|
        printf(template, pvm.name, host.name, host.ip_address)
      end
    end
  end 
end


class PVm < NetworkNameSpace
end
