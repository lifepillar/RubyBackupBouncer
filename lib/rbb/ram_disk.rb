# -*- coding: utf-8 -*-
module Rbb
  module RamDisk

    # Creates a new ram disk with a single unencrypted HFS+(J)
    # partition having the specified name and size. The disk is automatically
    # attached and its volume mounted at the default mount point (+/Volumes+).
    # Use :nomount to override this behavior.
    #
    # Returns a Device object.
    #
    # Currently, multiple partitions, different file systems, different image
    # types and encryption are not supported.
    #
    # [name]    The disk name.
    # [size]    The disk size (see Rbb::Utils#size_to_bytes)
    #
    # Options: nomount
    def self.create name, size, options = {}
      opts = {
        :nomount => false
      }.merge!(options)
      sz = Rbb::Utils.size_to_bytes(size)
      fs = (sz < 10*(2**20)) ? 'HFS+' : 'HFS+J'
      ram_path = 'ram://' + (sz / 512).to_s # ram://<number of 512-byte sectors>
      begin
        dev_node = (Rbb::Utils.hdiutil 'attach', '-nomount', ram_path).strip!
        Rbb::Utils.diskutil 'erasevolume', fs, name, dev_node
        return Rbb::Device.new(dev_node)
      rescue Exception => ex
        puts "Failed to create ram disk: #{ex}"
        return nil
      end
    end    
  end # module RamDisk
end # module Rbb
