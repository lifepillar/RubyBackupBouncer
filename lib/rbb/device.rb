# -*- coding: utf-8 -*-
require 'plist'

module Rbb

  # A class representing a device (an attached disk image or ram disk).
  class Device
    include Rbb::Utils

    attr_reader :dev_node

    # Creates a new Device instance. Raises an error if the
    # specified device node entry does not exist.
    #
    # [dev_node] A device entry specification (e.g., /dev/disk4).
    def initialize dev_node
      @dev_node = dev_node.to_s
     # raise "#{@dev_node} is not a valid device." unless self.valid?
    end

    # Returns true if this is a valid device; returns false otherwise.
    #
    # A “valid device” is a currently attached disk image or ram disk.
    def valid?
      not self.info.nil?
    end

    # Detaches this device.
    def detach
      run_baby_run 'hdiutil', ['detach', '-force', @dev_node], :err => '/dev/null'
    end

    # Returns a hash containing detailed information about this device.
    # Returns nil if this device is not attached.
    def info
      Plist::parse_xml(hdiutil 'info', '-plist')['images'].each do |disk_info|
        if @dev_node == disk_info['system-entities'][0]['dev-entry']
          return disk_info
        end
      end
      return nil
    end

    def [](key)
      disk_info = self.info
      return nil if disk_info.nil?
      return disk_info[key.to_s]
    end

    # Returns true if this device is attached in read-write mode;
    # returns false if this device is attached read-only or if it is not
    # attached at all.
    def writable?
      disk_info = self.info
      return false if disk_info.nil?
      return disk_info['writeable']
    end

    # Returns the disk image path associated to this device.
    def image_path
      self['image-path']
    end

    # Returns true if this device is a ram disk; returns false otherwise.
    def ram?
      (self['image-path'] =~ /^ram:\/\//) ? true : false
    end

    # Returns the (possibly empty) list of volumes in this device.
    # Returns nil if this device is not attached.
    def volumes
      disk_info = self.info
      return nil if disk_info.nil?
      v = []
      disk_info['system-entities'].each { |s| v << Volume.new(s['dev-entry']) }
      v.shift unless self.ram? # First entry is the disk node entry.
      return v
    end

    # Returns the first volume on this device.
    #
    # This is a convenience method, mostly for using with single-volume devices.
    def volume
      self.volumes[0]
    end

    # Returns a formatted string containing detailed information about this device.
    def pretty_info
      s = ''
      di = self.info
      return "No information for #{@dev_node}" if di.nil?
      device = di['system-entities'][0]['dev-entry']
      status = 'attached'
      rw = di['writeable'] ? 'read-write' : 'read-only'
      volumes = self.volumes
      if self.ram?
        type = '  Ram disk'
        where = self.image_path
      else
        type = 'Disk image'
        where = Pathname.new(self.image_path).basename
      end
      s << "#{type}: #{where} (#{device}, #{status}, #{rw})\n"
      s << '            -- volumes --' << "\n"
      volumes.each do |vol|
        s << '            ' + vol.pretty_info
      end
#      s << '            -------------' << "\n"
      return s
    end

  end # class Device

end # module Rbb
