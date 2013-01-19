# -*- coding: utf-8 -*-
require 'helper'

class TestUtils < MiniTest::Unit::TestCase

  def test_run_command_with_sudo
    puts 'An administrator password is required to run this test'
    refute_equal 'root', ENV['USER'] # Make sure we are not running as root
    assert_equal ENV['USER'] + "\n", Rbb::Utils.run_baby_run('whoami', [])
    assert_equal "root\n", Rbb::Utils.run_baby_run('whoami', [], :sudo => true)
  end

  def test_size_to_bytes
    assert_equal 512, Rbb::Utils.size_to_bytes('512')
    assert_equal 512, Rbb::Utils.size_to_bytes('1b')
    assert_equal 1024, Rbb::Utils.size_to_bytes('2b')
    assert_equal 1024, Rbb::Utils.size_to_bytes('1k')
    assert_equal 2048, Rbb::Utils.size_to_bytes('2k')
    assert_equal 1024*1024, Rbb::Utils.size_to_bytes('1m')
    assert_equal 1024*1024*1024, Rbb::Utils.size_to_bytes('1g')
    assert_equal Rbb::Utils.size_to_bytes('1024k'), Rbb::Utils.size_to_bytes('1m')
    assert_equal Rbb::Utils.size_to_bytes('1024m'), Rbb::Utils.size_to_bytes('1g')
  end

end # TestRBB


