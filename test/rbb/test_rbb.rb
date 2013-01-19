# -*- coding: utf-8 -*-
require 'helper'

class TestRBB < MiniTest::Unit::TestCase

  def test_dependencies_are_installed
    ['GetFileInfo', 'SetFile', 'xattr'].each do |cmd|
      assert_match(/#{cmd}/, `which #{cmd} 2>/dev/null`.chomp!,
        "Missing dependency: #{cmd}")
    end
  end

  def test_rbb_has_a_well_formed_version_number
    refute_nil Rbb::RBB_VERSION
    assert_match(/\d+\.\d+\.\d+/, Rbb::RBB_VERSION)
  end

end # TestRBB


