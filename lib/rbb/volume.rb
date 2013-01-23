# -*- coding: utf-8 -*-
require 'plist'

module Rbb

  # Represents a volume in a disk.
  class Volume
    include Rbb::Utils

    attr_reader :dev_node

    # Creates a new object for the specified volume. Raises an error if the
    # specified device node entry does not exist.
    def initialize dev_node
      di = Plist::parse_xml(diskutil 'info', '-plist', dev_node)
      raise "#{dev_node} is not a valid volume" if di.nil?
      @dev_node = di['DeviceNode']
    end

    # Returns a hash containing detailed information about this device.
    def info
      Plist::parse_xml(diskutil 'info', '-plist', @dev_node)
    end

    # Returns a formatted string containing detailed information about this volume.
    def pretty_info
      volinfo = self.info
      mountpoint = volinfo['MountPoint']
      mountpoint = 'Not mounted' if mountpoint.empty?
      rw = volinfo['WritableVolume'] ? 'writable' : 'read-only'
      ownership = self.ownership_enabled? ? 'ownership enabled' : 'no ownership'
      return volinfo['VolumeName'] + " (#{self.dev_node}, #{mountpoint}, #{rw}, #{ownership})\n"      
    end

    def [](key)
      di = self.info
      return nil if di.nil?
      return di[key.to_s]
    end

    # Returns the volume name.
    def name
      self['VolumeName']
    end

    # Mounts this volume. If :force_readonly is set to true, then the file
    # system is mounted read-only, even if the volume's underlying file system
    # and/or device and/or media supports writing; even the super-user may not
    # write to it; this is the same as the rdonly option to mount (8).
    #
    # Options: mountpoint, force_readonly
    def mount options = {}
      opts = {
        :force_readonly => false
      }.merge!(options)
      args = []
      args << 'readOnly'        if opts[:force_readonly]
      args << opts[:mountpoint] if opts.has_key?(:mountpoint)
      args << self.dev_node
      diskutil 'mount', *args
    end
  
    # Unmounts this volume.
    def unmount
      begin
        diskutil 'unmount', 'force', self.dev_node
      rescue Exception => ex
        debug "The volume #{self.dev_node} could not be unmounted: #{ex}"
      end
    end

    # Unmounts this volume, then mounts it again.
    #
    # Options: force_readonly
    def remount options = {}
      self.unmount
      self.mount options
    end

    # Tests whether this volume is mounted.
    def mounted?
      '' != self['MountPoint']
    end

    # Returns the mount point of this volume. Returns an empty string if this
    # volume is not mounted.
    def mount_point
      Pathname.new(self['MountPoint'])
    end

    # Renames this volume.
    def rename new_name
      diskutil 'rename', self.dev_node, new_name
    end

    # Enables ownership on this volume.
    #
    # Note that this command requires root privileges, so a password will be
    # asked if not running as root.
    def enable_ownership
      run_baby_run 'diskutil', ['enableOwnership', self.dev_node], :sudo => true
    end
  
    # Disables ownership on this volume.
    #
    # Note that this command requires root privileges, so a password will be
    # asked if not running as root.
    def disable_ownership
      run_baby_run 'diskutil', ['disableOwnership', self.dev_node], :sudo => true
    end

    # Tests whether ownership is enabled in this volume.
    def ownership_enabled?
      # 'diskutil info -plist' does not return information about ownership...
      ownership = `diskutil info #{self.dev_node} | grep 'Owners:'`
      return ownership =~ /Enabled/
    end

    # Returns true if this volume is mounted in read-write mode; returns false
    # if it is mounted read-only or if it is not mounted at all.
    def writable?
      self['WritableVolume']
    end

    # Returns the device containing this volume.
    def parent_whole_disk
      Device.new('/dev/' + self['ParentWholeDisk'])
    end

  end # class Volume
end # module Rbb
