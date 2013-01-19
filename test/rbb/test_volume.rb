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

class TestVolume < MiniTest::Unit::TestCase

  def setup
    @disk = Rbb::RamDisk.create 'TestDisk', '512k'
    @vol = @disk.volume
  end

  def teardown
    @disk.detach
    force_detach_ram_disks
  end

  def test_create_volume_instance
    assert_instance_of Rbb::Volume, @vol
    assert_equal 'TestDisk', @vol.name
    assert_instance_of Pathname, @vol.mount_point
    assert_match(/^\/Volumes\/TestDisk/, @vol.mount_point.to_s, 'Wrong mount point')
    assert @vol.writable?, 'The volume should be writable by default'
    refute @vol.ownership_enabled?, 'Ownership should be disabled by default'
  end

  def test_mount_and_unmount_volume
    assert @vol.mounted?, 'The volume should be mounted'
    @vol.unmount
    refute @vol.mounted?, 'The volume should be unmounted'
    @vol.mount
    assert @vol.mounted?, 'The volume should be mounted again'
    assert @vol.writable?, 'The volume should be writable'
    @vol.remount :force_readonly => true
    refute @vol.writable?, 'The volume should be read-only'
  end

  def test_enabling_and_disabling_ownership
    puts 'An administrator password is required to run this test'
    @vol.enable_ownership
    assert @vol.ownership_enabled?, 'Ownership should be enabled'
    @vol.disable_ownership
    refute @vol.ownership_enabled?, 'Ownership should be disabled'
  end

end # TestVolume
