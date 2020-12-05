#!/usr/bin/env ruby

$LOAD_PATH.unshift File.expand_path( File.join File.dirname( __FILE__ ),"")

require "pp"

ENV["LANG"] = "C"

def usage
  cmdstr = ""
  header = "USAGE: tenv" 
  spacer = " " * header.size + " "
  cmdstr = `ls *_cli.rb`.split("\n").inject(""){|cmdstr, cli| cmdstr += cli.strip.gsub(/_cli.rb/,"\n#{spacer}")}

  puts  "#{header} #{cmdstr}"
end

if ARGV.size < 1
  usage
  exit 1
end

dir = `dirname #{$0}`.chomp
subcommand = ARGV[0]
ARGV.shift
puts `ruby #{dir}/#{subcommand}_cli.rb #{ARGV.join(" ")}`
