# -*- coding: utf-8 -*-
require 'rubygems' if RUBY_VERSION < "1.9"
require 'bundler/setup'
require 'rbb'

# Test directory
TEST_WD = Pathname.new(__FILE__).dirname.realpath
# Test data
TEST_DATA_DIR = TEST_WD + 'data'

# The following is to turn off warnings that silence_warnings does not suppress.
module Turn
  module Colorize
    @colorize = nil
  end
end

silence_warnings do
  begin
    require 'turn/autorun'
    Turn.config do |c|
      #c.tests = ["test/**/{test,}*{,test}.rb"] # Default
      #c.exclude = [] # Default
      #c.pattern = /.*/ # Default
      #c.loadpath = ['lib'] # Default
      c.format = :pretty # :pretty, :dot, :cue, :marshal, :outline, :progress
      c.natural = true # Use natural language case names
    end
  rescue LoadError
    require 'minitest/autorun'
  end
end

def force_detach_ram_disks
  Plist::parse_xml(Rbb::Utils.hdiutil 'info', '-plist')['images'].each do |disk_info|
    if disk_info['image-path'] =~ /ram:\/\//
      Rbb::Utils.hdiutil 'detach', '-force', disk_info['system-entities'][0]['dev-entry']
    end
  end  
end
