# -*- coding: utf-8 -*-
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

  def test_parent_whole_disk
    device = @vol.parent_whole_disk
    refute_nil device
    assert_instance_of Rbb::Device, device
    assert @vol.dev_node.start_with?(device.dev_node)
  end

end # TestVolume
