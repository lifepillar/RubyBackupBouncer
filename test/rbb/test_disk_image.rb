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

class TestDiskImageCreation < MiniTest::Unit::TestCase

  def setup
    @path = TEST_DATA_DIR + 'TestDiskImage.sparseimage'
    @di = Rbb::DiskImage.create 'TestDiskImage', '40M', :dir => TEST_DATA_DIR
  end

  def teardown
    @di.detach if @di.attached?
    @di.image_path.unlink if @di.image_path.exist? # Make sure the file is deleted
  end

  def test_create_40m_disk_image_with_default_options
    assert_instance_of Rbb::DiskImage, @di, 'The created object is not a DiskImage object'
    assert_equal @path, @di.image_path
    assert_match(/^\/dev\/disk\d+/, @di.dev_node, 'Device node should be defined')
    assert_match(/^\/disk\d+/, @di.partial_dev_node, 'Partial device node should be defined')
    disk_info = @di.info
    assert_instance_of Hash, disk_info, 'DiskImage#info should return a hash'
    assert_equal @di.image_path.to_s, disk_info['image-path']
    assert_equal @di.dev_node, disk_info['system-entities'][0]['dev-entry']
    assert true == disk_info['writeable'], 'The disk image should be writable by default'
    @di.detach
    refute @di.attached?, 'The disk image should not be attached any longer'
  end

end # TestDiskImageCreation

class TestDiskImageVolumes < MiniTest::Unit::TestCase

  def setup
    @di = Rbb::DiskImage.create 'TestDiskImage', '40M', :dir => TEST_DATA_DIR
  end

  def teardown
    @di.detach if @di.attached?
    @di.image_path.unlink if @di.image_path.exist? # Make sure the file is deleted
  end

  def test_volumes
    assert @di.attached?, 'The disk image should be attached'
    assert_instance_of Rbb::Device, @di.device
    vol = @di.device.volumes
    assert_instance_of Array, vol
    assert_equal 1, vol.size
    assert_instance_of Rbb::Volume, vol[0]
    assert_equal 'TestDiskImage', vol[0].name
  end
  
end # TestDiskImageVolumes
