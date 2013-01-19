# -*- coding: utf-8 -*-

# To silence (most) warnings from a required file.
module Kernel # :nodoc:
  def silence_warnings
    with_warnings(nil) { yield }
  end

  def with_warnings(flag)
    old_verbose, $VERBOSE = $VERBOSE, flag
    yield
  ensure
    $VERBOSE = old_verbose
  end
end unless Kernel.respond_to? :silence_warnings

if RUBY_VERSION < "1.9"
  class String # :nodoc:
    def force_encoding enc
      self
    end
  end
end

require 'minitest/unit'

# Override test_order to produce tests in alphabetical order (default is randomly sorted)
module MiniTest
	class Unit
		class TestCase
			def self.test_order
				:alpha
			end
		end
	end
end

module Rbb
  # Ruby Backup Bouncer version.
  RBB_VERSION = '0.0.1'
  RBB_USER_AGENT = "Ruby Backup Bouncer #{RBB_VERSION} (Ruby #{RUBY_VERSION}-#{RUBY_PATCHLEVEL}; #{RUBY_PLATFORM})"
end

require 'rbb/utils'
require 'rbb/pathname'
require 'rbb/volume'
require 'rbb/device'
require 'rbb/ram_disk'
require 'rbb/disk_image'
require 'rbb/test_case'
