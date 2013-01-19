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
require 'plist'
require 'helper'
  
class TestRamDiskCreation < MiniTest::Unit::TestCase

  def teardown
    force_detach_ram_disks
  end

  def test_40MB_ram_disk
    rd = Rbb::RamDisk.create 'TestRamDisk', '40M'
    assert_instance_of Rbb::Device, rd
    assert rd.valid?, 'The ram disk should be a valid device'
    assert rd.ram?, 'The device should be a ram disk'
    assert_equal rd.dev_node, rd.info['system-entities'][0]['dev-entry']
    assert rd.writable?, 'The ram disk should be writable'
    assert_equal rd.image_path, 'ram://81920'
    rd.detach
    refute rd.valid?, 'The ram disk should not be valid any longer'
  end

  def test_readonly_nomount_1MB_ram_disk
    rd = Rbb::RamDisk.create 'TestRamDisk', '1M', :nomount => true
    assert_instance_of Rbb::Device, rd
    assert rd.valid?, 'The ram disk should be a valid device'
    assert rd.ram?, 'The device should be a ram disk'
    assert_equal rd.dev_node, rd.info['system-entities'][0]['dev-entry']
    assert rd.writable?, 'The ram disk should be writable'
    assert_equal rd.image_path, 'ram://2048'
    rd.detach
    refute rd.valid?, 'The ram disk should not be valid any longer'
  end

end # TestRamDiskCreation

class TestRamDiskVolumes < MiniTest::Unit::TestCase

  def setup
    @rd = Rbb::RamDisk.create 'TestRamDisk', '1M'
  end

  def teardown
    @rd.detach
    force_detach_ram_disks
  end

  def test_volumes
    vol = @rd.volumes
    assert_instance_of Array, vol
    assert_equal 1, vol.size
    assert_instance_of Rbb::Volume, vol[0]
  end

end # TestRamDiskVolumes

class TestTwoRamDisks < MiniTest::Unit::TestCase

  def setup
    @rd1 = Rbb::RamDisk.create 'TestRamDisk1', '1M'
    @rd2 = Rbb::RamDisk.create 'TestRamDisk2', '1M'
  end

  def teardown
    @rd1.detach
    @rd2.detach
    force_detach_ram_disks
  end

  def test_distinguish_between_ram_disks
    assert @rd1.valid?, 'First ram disk not attached'
    assert @rd2.valid?, 'Second ram disk not attached'
    disk1_info = @rd1.info
    disk2_info = @rd2.info
    assert_equal @rd1.dev_node, disk1_info['system-entities'][0]['dev-entry']
    assert_equal @rd2.dev_node, disk2_info['system-entities'][0]['dev-entry']
    refute_equal @rd1.dev_node, @rd2.dev_node
  end

end # TestTwoRamDisks
