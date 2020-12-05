# -*- coding: euc-jp -*-
require "tenv_config"

class RemoteCommandExecuter
  include TEnvConfig

  def initialize(ip_address)
    @ip_address = ip_address
  end

  #=== exec by ssh
  #_opts[:root]_ :: exec command as root
  #_opts[:stdout]_ :: specified variable that stdout data is stored to
  def exec(command, opts = {})
    res = ""
    stdout = ""
    Net::SSH.start(@ip_address, 
                   PVMHOST_LOGIN_ACCOUNT , 
                   :password => PVMHOST_LOGIN_PASSWD) do |ssh|
      if opts[:root]
        ssh.open_channel do |channel|
          channel.exec("sudo -S #{command}") do |ch, success|
            raise "could not exec command sudo -S ls" unless success
            channel.on_data do |ch, data|
              res = data
            end
            channel.on_extended_data do |ch, type, data|
              # "got stderr: #{data}"
              stdout += data
              opts[:stdout] += data if opts[:stdout]
            end
            channel.on_process do |ch|
              channel.eof! if channel.output.empty?
            end
          end
          channel.send_data("#{PVMHOST_ROOT_PASSWD}\n")
        end
        ssh.loop
      else
        res = ssh.exec!(command)
      end
    end
#    puts "#{command} => #{res} #=> #{stdout}"
    return res
  end

  #http://takuya-1st.hatenablog.jp/entry/20110919/1316426672
  def scp(local, remote, opts = {})
    if opts[:download]
      c="scp #{PVMHOST_LOGIN_ACCOUNT}@#{@ip_address}:#{remote} #{local}"
    elsif opts[:upload]
      c="scp #{local} #{PVMHOST_LOGIN_ACCOUNT}@#{@ip_address}:#{remote}"
    end
    PTY.getpty("#{c} 1> /dev/null 2> /dev/null") do |i, o|
      o.sync = true
      i.expect(/password:/,10){|line| ##入力プロンプトくるまでreadline繰り返す
        puts line
        o.puts "#{PVMHOST_LOGIN_PASSWD}"
        o.flush
      }
      while( i.eof? == false )
        puts i.gets
      end
    end
  end
end

class LocalCommandExecuter
  def initialize(ip_address)
    @ip_address = ip_address
  end

  def exec(command, opts = {})
    if opts[:root]
      #TODO: qqq sudo it
      `#{command}`
    else
      `#{command}`
    end
  end

  def scp(local, remote, opts = {})
    #nothing to do ...
  end  
end

class CommandExecuter
  def self.create(ip_address)
    if ip_address == "127.0.0.1"
      return LocalCommandExecuter.new(ip_address)
    else
      return RemoteCommandExecuter.new(ip_address)
    end
  end
end
