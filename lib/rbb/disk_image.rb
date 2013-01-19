# -*- coding: utf-8 -*-
require 'pathname'
require 'plist'

module Rbb

  class DiskImageExists < Exception; end

  # A class representing a disk image.
  class DiskImage
    include Rbb::Utils

    # Creates a new sparse image with a single unencrypted HFS+(J)
    # partition having the specified name and size. The disk is automatically
    # attached and its volume mounted at the default mount point (+/Volumes+).
    # Use :nomount and :noattach to override this behavior.
    #
    # Returns a DiskImage object.
    #
    # Raises an exception if the given path already exists, unless :overwrite is true.
    #
    # Currently, multiple partitions, different file systems, different image
    # types and encryption are not supported.
    #
    # Options: dir, noattach, nomount, overwrite, readonly
    def self.create name, size, options = {}
      opts = {
        :dir => Pathname.pwd,
        :noattach => false,
        :nomount => false,
        :overwrite => false,
        :readonly => false
      }.merge!(options)
      dmg_path = (Pathname.new(opts[:dir]) + (name + '.sparseimage')).expand_path
      raise DiskImageExists if dmg_path.exist? and not opts[:overwrite]
      sz = Rbb::Utils.size_to_bytes(size)
      fs = (sz < 10*(2**20)) ? 'HFS+' : 'HFS+J'
      Rbb::Utils.hdiutil 'create', '-size', sz, '-fs', 'HFS+J',
        '-volname', name, '-type', 'SPARSE', dmg_path
      di = DiskImage.new(dmg_path)
      di.attach(opts) unless opts[:noattach]
      return di
    end
      
    attr_reader :image_path

    # Creates a new DiskImage instance.
    #
    # [path] The path to a disk image file.
    #
    # Example:
    #
    #  di = DiskImage.new('./my_image.sparseimage')
    def initialize path
      @image_path = Pathname.new(path).expand_path
    end

    # Returns a hash containing detailed information about this disk.
    # Returns nil if this disk is not attached.
    def info
      Plist::parse_xml(hdiutil 'info', '-plist')['images'].each do |disk_info|
        return disk_info if @image_path.to_s == disk_info['image-path']
      end
      return nil
    end

    # Returns a formatted string containing detailed information about this disk.
    def pretty_info
      s = ''
      dev = self.device
      return "Disk image: #{self.image_path.basename} (na, detached, na)\n" if dev.nil?
      return dev.pretty_info
    end

    def [](key)
      disk_info = self.info
      return nil if disk_info.nil?
      return disk_info[key.to_s]        
    end

    # Returns the device entry corresponding to this disk image,
    # if this disk is attached.
    # Returns nil if this disk is not attached or it does not exist.
    def dev_node
      disk_info = self.info
      return nil if disk_info.nil?
      return disk_info['system-entities'][0]['dev-entry']
    end

    def partial_dev_node
      pdn = self.dev_node
      return nil if pdn.nil?
      return pdn.sub('/dev','')
    end

    # Returns a Device object corresponding to this disk, if this disk is attached.
    # Returns nil if this disk is not attached or it does not exist.
    #
    # See also: Device
    def device
      dev_entry = self.dev_node
      return nil if dev_entry.nil?
      return Device.new(dev_entry)
    end

    # Attaches this disk image and mounts all its volumes at the default
    # mount point (+/Volumes+) or at the mount point specified with :mountpoint,
    # unless :nomount is set to true.
    #
    # Options: readonly, nomount, mountpoint
    def attach options = {}
      opts = {
        :readonly => false,
        :nomount => false
      }.merge!(options)
      args = [@image_path, '-mount']
      args << (opts[:nomount] ? 'suppressed' : 'required')
      args << '-readonly' if opts[:readonly]
      args << '-mountpoint' << opts[:mountpoint] if opts.has_key?(:mountpoint)
      hdiutil 'attach', *args
    end

    # Detaches this disk image.
    def detach
      begin
        run_baby_run 'hdiutil', ['detach', '-force', self.dev_node], :err => '/dev/null'
      rescue Exception => ex
        debug "The disk image at #{@dev_node} could not be detached: #{ex}"
      end
    end

    # Detaches this disk image and attaches it again.
    #
    # See also: #attach
    #
    # Options: readonly, mountpoint
    def reattach options = {}
      self.detach
      self.attach options
    end

    # Returns true if this disk is attached; returns false otherwise.
    def attached?
      not self.info.nil?
    end

    # Returns true if this disk image is attached in read-write mode;
    # returns false if this image is attached read-only or if it is not
    # attached at all.
    def writable?
      dev = self.device
      return false if dev.nil?
      return dev.writable?
    end

  end # class DiskImage

end # module Rbb
