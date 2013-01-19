# -*- coding: utf-8 -*-
require 'tempfile'

class Pathname
  include Rbb::Utils

  def cd
    Dir.chdir(self) { yield }
  end

  # Returns a temporary file. As a rule, after finishing using the file, it
  # should be closed and unlinked.
  #
  # Options: basename, basedir
  def self.tempfile options = {}
    basename = options.has_key?(:basename) ? options[:basename] : 'tempfile'
    if options.has_key?(:basedir)
      bd = Pathname.new(options[:basedir])
      bd.mkpath
      return Pathname.new(Tempfile.new(basename, bd.to_s).path)
    else
      return Pathname.new(Tempfile.new(basename).path)
    end
  end


  # Returns a temporary directory. As a rule, after finishing using it, it
  # should be unlinked.
  def self.tempdir
    # I used /tmp rather than `mktemp -td` because that generates a directory
    # name with exotic characters like + in it, and these break badly written
    # scripts that don't escape strings before trying to regexp them :(

    # If the user has FileVault enabled, then we can't mv symlinks from the
    # /tmp volume to the other volume. So we let the user override the tmp
    # prefix if they need to.
    tmp_prefix = '/tmp'
    tmp = Pathname.new `mktemp -d #{tmp_prefix}/temp_item-XXXXXX`.strip
    raise "Couldn't create temporary directory" if not tmp.directory? or $? != 0
    return tmp.realpath # /tmp is a symlink to /private/tmp in OS X
  end

  # Writes data into self, overwriting any existing data.
  #
  # If :compressed is set to true, enables HFS+ compression.
  # If :rsrc is not nil, compiles the specified resource fork into the file.
  #
  # Options: compressed, rsrc
  def write data, options = {}
    opts = { :compressed => false, :rsrc => nil }.merge!(options)
    if opts[:compressed]
      unless opts[:rsrc].nil?
        # Tested on OS X 10.8 (Mountain Lion)
        puts 'WARNING: resource forks preclude the ability to use HFS+ compression.'
      end
      p = Pathname.tempfile
      p.open("w") { |f| f.write(data) }
      p.rez(opts[:rsrc]) unless opts[:rsrc].nil?
      run_baby_run 'ditto', ['--hfsCompression', p, self]
      p.unlink
    else
      self.open("w") { |f| f.write(data) }      
      self.rez(opts[:rsrc]) unless opts[:rsrc].nil?
    end
  end

  # Writes random data into a file.
  #
  # See also: Pathname#write
  #
  # Options: compressed, rsrc
  def write_random length = 0, options = {}
    self.write(random_string(size_to_bytes(length)), options)
  end

  # Returns true if self has the same (byte by byte) content as the specified
  # path; returns false otherwise. Note that this method does not compare any
  # metadata.
  def compare path
    begin
      run_baby_run 'cmp', ['--quiet', self, path], :sudo => (not self.owned?)
      return true
    rescue
      return false
    end
  end

  # Returns the inode of this file, without following symbolic links.
  def inode
    File.lstat(self.to_s).ino
  end

  # Returns the owner id of this file, without following symbolic links.
  def owner
    File.lstat(self.to_s).uid
  end

  # Returns the group id of this file, without following symbolic links.
  def group
    File.lstat(self.to_s).gid
  end

  # Returns the permissions of this file, without following symbolic links.
  def permissions
    File.lstat(self.to_s).mode
  end

  # Returns the number of hard links to this file.
  def num_hardlinks
    File.lstat(self.to_s).nlink
  end

  # Returns the size of this object. If this pathname is a symbolic link,
  # then returns the size of the link, not the size of the file pointed to by
  # the link.
  #
  # See also: #size
  def lsize
    File.lstat(self.to_s).size
  end

  # Returns the number of native file system blocks allocated for this file.
  # If this pathname is a symbolic link, returns the the number of blocks
  # allocated for the link, not the the number of blocks of the referenced file.
  def blocks
    File.lstat(self.to_s).blocks
  end

  # Returns the creation date of this object, without following symlinks.
  # Returns a string of the form "mm/dd/yyyy hh:mm:ss" in 24-hour clock format.
  #
  # See also: man GetFileInfo
  def creation_time
    (run_baby_run 'GetFileInfo', ['-P', '-d', self]).chomp!
  end

  # Sets the creation date, where date is a string of the form:
  # "mm/dd/[yy]yy [hh:mm:[:ss] [AM | PM]]".
  #
  # See also: man SetFile
  def creation_time=(timestamp)
    run_baby_run 'SetFile', ['-P', '-d', timestamp, self], :sudo => (not self.owned?)
  end

  # Returns the modification time of self as a string of the form
  # "mm/dd/yyyy hh:mm:ss" in 24-hour clock format.
  #
  # Unlike #mtime, this method does not follow symbolic links.
  def modification_time
    (run_baby_run 'GetFileInfo', ['-P', '-m', self]).chomp!
  end

  # Sets the modification date where date is a string of the form:
  # "mm/dd/[yy]yy [hh:mm:[:ss] [AM | PM]])"
  #
  # See also: SetFile
  def modification_time=(timestamp)
    run_baby_run 'SetFile', ['-P', '-m', timestamp, self], :sudo => (not self.owned?)
  end

  # See also: man GetFileInfo
  def attributes
    (run_baby_run 'GetFileInfo', ['-P', '-a', self]).chomp!
  end

  # Returns true if the given flag is set; returns false otherwise.
  #
  # See also: man GetFileInfo
  def attribute? letter
    flag = run_baby_run 'GetFileInfo', ['-P', "-a#{letter}", self]
    return flag.to_i == 1
  end

  # Sets the uchg flag.
  def lock
    run_baby_run 'chflags', ['uchg', self], :sudo => (not owned?)
  end

  # Unsets the uchg flags.
  def unlock
    run_baby_run 'chflags', ['nouchg', self], :sudo => (not owned?) 
  end

  # Returns true if this path is locked (uchg flag is set); returns false otherwise.
  def locked?
    self.attribute?('l')   
  end

  # Returns the creator, a string of exactly four characters.
  #
  # See also: man GetFileInfo
  def creator
    c = run_baby_run('GetFileInfo', ['-P', '-c', self])
    # We evaluate the result because the returned string is enclosed in
    # double-quotes and may contain escaped sequences
    # (e.g., the creator string may be "\0\0\0\0").
    return eval(c)
  end

  # Sets the creator. The argument must be a string of length 4.
  def creator=(code)
    raise "#{code} is not a valid creator code" unless 4 == code.length
    run_baby_run 'SetFile', ['-P', '-c', code, self], :sudo => (not self.owned?)
  end

  # Returns the file type, a string of exactly four characters.
  # If the type is not set, these will display as an empty pair of quotation
  # marks. Note that directories do not have types.
  #
  # See also: man GetFileInfo
  def kind
    k = run_baby_run('GetFileInfo', ['-P', '-t', self])
    # See #creator
    return eval(k)
  end

  # Sets the file's type. The argument must be a 4-letter string.
  def kind=(code)
    raise "#{code} is not a valid file's type" unless 4 == code.length
    run_baby_run 'SetFile', ['-P', '-t', code, self], :sudo => (not self.owned?)
  end

  def file_type
    (run_baby_run 'stat', ['-f', '%HT:%r', self]).chomp!
  end

  # Returns an integer representing the BSD flag status for this file,
  # without following symbolic links. Note that the HFS+ compression flag
  # is always masked. Use #compressed? to check whether that flag is enabled.
  #
  # BSD flags layout:
  #
  #   19 18 17 16 … 9 8 7 6 5 4 3 2 1
  #
  #   19 = sappend
  #   18 = schg
  #   17 = arch
  #   16 = hidden
  #   9 =
  #   8 =
  #   7 =
  #   6 = HFS+ compression enabled
  #   5 =
  #   4 = opaque
  #   3 = uappend
  #   2 = uchg
  #   1 = nodump
  def bsd_flags
    flags = run_baby_run 'stat', ['-f', '%f', self]
    return flags.to_i & 01777737 # Mask HFS+ compression flag
  end

  # Returns true if this file used HFS+ compression; returns false otherwise.
  def compressed?
    return (((run_baby_run 'stat', ['-f', '%f', self]).to_i) & 040) == 040
  end

  # Returns the ACL for this file. Returns an empty string if no ACL is defined.
  def acl
    `ls -Plde '#{self}' | tail -n +2`.chomp!
  end

  # Returns an MD5 digest for this file.
  def md5
    (run_baby_run 'md5', ['-q', self], :sudo => (not self.owned?)).chomp!
  end

  # Makes this pathname a Finder alias pointing to the specified path.
  #
  # See also: #make_link, #make_symlink
  def make_alias original_path
    p = Pathname.new(original_path)
    script  = 'tell application "Finder" to make new alias file'
    script << " at POSIX file \"#{self.dirname}\""
    script << " to POSIX file \"#{p}\""
    script << " with properties {name:\"#{self.basename}\"}"
    run_baby_run 'osascript', ['-e', script], :err => '/dev/null'
  end

  # Returns true if self is a Finder alias; returns false otherwise. A Finder
  # alias is a file created in the Finder by choosing File > Make Alias.
  #
  # Note that this method returns false if self is a symbolic link.
  def alias?
    (not self.symlink?) and self.attribute?('a')
  end

  # Returns the pathname of the original item referred to by self.
  # Returns nil if the alias or symlink cannot be resolved.
  #
  # This method extends #realpath to add the ability to resolve Finder aliases.
  #
  # See also: #realpath
  def original
    if self.alias?
      pre = "set a to \"#{self}\" as POSIX file"
      script = 'tell application "Finder" to get the POSIX path of ((the original item of alias file a) as text)'
      begin
        item = run_baby_run('osascript', ['-e', pre, '-e', script], :sudo => (not self.owned?), :err => '/dev/null')
        return Pathname.new(item.chomp!)
      rescue
        return nil
      end
    else
      begin
        return self.realpath
      rescue
        return nil
      end
    end
  end

  # Returns the Spotlight comment for this file.
  def spotlight_comment
    dir = "set linkFolderHFS to \"#{self.dirname}\" as POSIX file as text"
    type = self.directory? ? 'folder' : 'file'
    script  = 'tell application "Finder"'
    script += " to get the comment of #{type} \"#{self.basename}\" of folder linkFolderHFS"
    debug script
    comment = run_baby_run 'osascript', ['-e', dir, '-e', script]
    return comment.chomp!
  end

  # Sets a Spotlight comment for this file.
  def spotlight_comment=(comment)
    # The convoluted way in which we specify the path to the file
    # allows the script to set a comment on a symlink
    # (see this thread at MacScripter:
    #  http://macscripter.net/viewtopic.php?pid=134492)
    type = self.directory? ? 'folder' : 'file'
    dir = "set linkFolderHFS to \"#{self.dirname}\" as POSIX file as text"
    script  = 'tell application "Finder"'
    script += " to set the comment of #{type} \"#{self.basename}\" of folder linkFolderHFS to \"#{comment}\""
    debug script
    run_baby_run 'osascript', ['-e', dir, '-e', script], :out => '/dev/null', :sudo => (not self.owned?)
    sleep 0.5 # Seems necessary for the comment to "stick"
    return
  end

  # Compiles the given resource fork into self. The argument is the textual
  # specification of a resource fork.
  #
  # Examples of resources in Rez input format are in the test/data directory.
  # A further example can be found at http://scv.bu.edu/~putnam/ag-audio/source-2.4/ag-media-positional/tk-8.0/mac/tkMacResource.r.
  #
  # See also:
  # * http://developer.apple.com/legacy/mac/library/documentation/mac/pdf/MoreMacintoshToolbox.pdf
  # * http://www.mactech.com/articles/mactech/Vol.03/03.02/Rez-ervations/index.html
  # * http://xahlee.info/UnixResource_dir/macosx.html
  def rez rsrc
    r = Pathname.tempfile
    r.write(rsrc)
    run_baby_run 'Rez', ['-o', self, 'Carbon.r', r]
    r.unlink
  end

  # Decompiles and returns the resource fork of self as a String object.
  def derez
    begin
      rsrc = run_baby_run 'DeRez', [self], :err => '/dev/null', :sudo => (not self.owned?)
    rescue
      return '' if 2 == $?.exitstatus # Empty or uninitialized resource fork
    end
    rsrc.force_encoding('macRoman')
    debug rsrc
    debug rsrc.encoding.name if RUBY_VERSION >= "1.9"
    return rsrc
  end

  # Returns a hexadecimal dump of the resource fork.
  def rez_dump
    run_baby_run 'hexdump', ["#{self}/..namedfork/rsrc"], :sudo => (not self.owned?)
  end

  # Returns a list of the names of the extended attributes associated to self.
  # If self is a symbolic link, acts on the symbolic link itself.
  #
  # Note that this method (like #set_attr) uses OS X xattr,
  # which does not expose hidden extended attributes, such as HFS+
  # compression. This is fine, because we may test for HFS+ compression
  # separately (see #compressed?).
  #
  # See also: #xattr, #set_xattr
  def extended_attributes
    # xattr is not permitted on special files and does not work with broken symlinks
    return [] if self.file_type =~ /Fifo|Device/ or (not self.exist?)
    xattrs = run_baby_run '/usr/bin/xattr', ['-s', self], :sudo => (not self.owned?)
    return xattrs.split("\n").each { |x| x.strip! }
  end

  # Returns the value of the given extended attribute.
  # Returns nil if the attribute is not present.
  # If self is a symbolic link, acts on the symbolic link itself.
  #
  # This method can also be used to retrieve hidden extended attributes,
  # such as com.apple.decmpfs, which the xattr executable would not normally expose.
  #
  # See also: #extended_attributes, #set_xattr, man xattr
  def xattr name
    # xattr is not permitted on special files and does not work with broken symlinks
    return nil if self.file_type =~ /Fifo|Device/ or (not self.exist?)
    # /usr/bin/xattr does not expose the com.apple.decmpfs extended attribute,
    # and hides com.apple.ResourceFork for files with HFS+ compression enabled
    # in the resource fork. In these cases, we use xattr-util instead of xattr.
    if 'com.apple.decmpfs' == name or ('com.apple.ResourceFork' == name and self.compressed?)
      xattr_util = Pathname.new(__FILE__).parent.parent.parent + 'bin/xattr-util'
      begin
        return (run_baby_run xattr_util, ['--get', name, self], :err => '/dev/null', :sudo => (not self.owned?)).chomp!
      rescue
        return nil
      end
    else
      begin
        return (run_baby_run '/usr/bin/xattr', ['-s', '-p', name, self], :err => '/dev/null', :sudo => (not self.owned?)).chomp!
      rescue
        return nil
      end
    end
  end

  # Sets the value of the given extended attribute.
  # If self is a symbolic link, acts on the symbolic link itself.
  #
  # See also: #extended_attributes, #xattr, man xattr
  def set_xattr name, value
    run_baby_run '/usr/bin/xattr', ['-s', '-w', name, value, self], :sudo => (not self.owned?)
  end

end # Pathname
