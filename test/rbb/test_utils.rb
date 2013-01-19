# -*- coding: utf-8 -*-

# Copyright (c) 2012 Lifepillar
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
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


