# -*- coding: utf-8 -*-
require 'rubygems' if RUBY_VERSION < "1.9"
require 'bundler/setup'
require 'pathname'
begin; require 'rdoc/task'; rescue LoadError; end

$LOAD_PATH.unshift(Pathname.new(__FILE__).dirname + 'lib')
require 'rbb'
include Rbb::Utils

RAM_DISKS_ENABLED   = true
DEFAULT_FOLDER_NAME = 'srcdir'
DEFAULT_VOLUME_NAME = 'srcvol'
DEFAULT_VOLUME_SIZE = '140M'
DIR_VOLUMES         = Pathname.new(__FILE__).parent + 'volumes'
DIR_TMP             = Pathname.new(__FILE__).parent + 'tmp'
DIR_TESTS           = Pathname.new(__FILE__).parent + 'tests'
DIR_COPIERS         = Pathname.new(__FILE__).parent + 'copiers'
TXT_DEFAULT_COPIERS = DIR_COPIERS + 'default.txt'
TXT_DEFAULT_TESTS   = DIR_TESTS   + 'default.txt'
TXT_ENABLED_COPIERS = DIR_COPIERS + 'enabled.txt'
TXT_ENABLED_TESTS   = DIR_TESTS   + 'enabled.txt'

CLEAN =
  Pathname.glob(DIR_TMP+'*') +
  Pathname.glob(DIR_VOLUMES+'*') -
  [DIR_VOLUMES+(DEFAULT_VOLUME_NAME+'.sparseimage')]
CLOBBER =
  [DIR_VOLUMES+(DEFAULT_VOLUME_NAME+'.sparseimage')] +
  [Pathname.new('pkg')] +
  Pathname.glob('**/.DS_Store')

DIR_VOLUMES.mkpath
DIR_TMP.mkpath

unless TXT_ENABLED_COPIERS.exist?
  cp TXT_DEFAULT_COPIERS, TXT_ENABLED_COPIERS, :verbose => false
end
unless TXT_ENABLED_TESTS.exist?
  cp TXT_DEFAULT_TESTS, TXT_ENABLED_TESTS, :verbose => false
end

$enabled_copiers = TXT_ENABLED_COPIERS.read.split(/\n/)
$enabled_tests   = TXT_ENABLED_TESTS.read.split(/\n/)


# Returns the list of managed disk images.
def disk_images
  DIR_VOLUMES.entries.reject { |f| '.sparseimage' != f.extname }.map do |f|
    Rbb::DiskImage.new(DIR_VOLUMES+f)
  end
end

# Returns the list of ram disks.
def ram_disks
  rd = []
  rec = Plist::parse_xml(`hdiutil info -plist`)['images'].reject do |e|
    e['image-path'] !~ /^ram:\/\//
  end
  rec.each do |r|
    ramdisk = Rbb::Device.new(r['system-entities'][0]['dev-entry'])
    rd << ramdisk
  end
  return rd
end

# Returns the list of attached disk images and ram disks.
def devices
  disk_images.select { |d| d.attached? }.map { |d| d.device } + ram_disks
end

# Tries to find a device with a given name.
# Returns the device entry if found, nil otherwise.
def device_by_name name
  devices.each do |device|
    if name == device.volume.name
      return device
    end
  end
  return nil
end

# Creates and mounts a single volume disk image or ram disk.
#
# The created volume has ownership enabled by default.
#
# Options: size, ram
def make_volume name, options = {}
  opts = { :size => DEFAULT_VOLUME_SIZE, :ram => false }.merge!(options)
  if opts[:ram] and RAM_DISKS_ENABLED
    raise Rbb::DiskImageExists if (Pathname.new('/Volumes')+name).exist?
    volume = Rbb::RamDisk.create(name, opts[:size]).volume
  else
    raise Rbb::DiskImageExists if (DIR_VOLUMES+(name+'.sparseimage')).exist?
    volume = Rbb::DiskImage.create(name, opts[:size]).device.volume
 end
 volume.enable_ownership
 return volume
end

def abort_if_bsd_system_flags_enabled
  if $enabled_tests.include?('bsd_system_flags')
    abort "The bsd_system_flags test case must be disabled to run this task:\n\n" +
      "    rake disable[bsd_system_flags]\n"
  end
end


# TASKS

desc <<-EOS
Attach a disk image.

Examples:

- To attach the default source image (./#{DIR_VOLUMES.basename}/#{DEFAULT_VOLUME_NAME}.sparseimage):

    rake attach

- To attach ./volumes/test.sparseimage:

    rake attach dmg=./volumes/test.sparseimage
  or
    rake attach[./volumes/test.sparseimage]
EOS
task :attach, [:dmg] do |t,args|
  args.with_defaults(:dmg => ENV['dmg'] || DIR_VOLUMES+(DEFAULT_VOLUME_NAME+'.sparseimage'))
  p = Pathname.new(args.dmg).expand_path
  abort "#{p} does not exist." unless p.exist?
  Rbb::DiskImage.new(p).attach
  puts 'Done.'
end

desc "Attach all the disk images in ./#{DIR_VOLUMES.basename}."
task :attachall do
  disk_images.each { |di| di.attach }
end

desc 'Execute both autoclone and autocopy.'
task :auto => [:autoclone, :autocopy] do
end

desc 'Copy and verify with all enabled copiers and tests.'
task :autocopy => [:mkvol, :fill, :copy] do
  Pathname.glob(DIR_TMP+'*').each do |d|
    next unless d.directory?
    puts "===> [verify] #{d.basename}" 
    Rake::Task['verify'].reenable
    Rake::Task['verify'].invoke('/Volumes/'+DEFAULT_VOLUME_NAME, d.to_s)
  end
end

desc 'Clone and verify with all enabled copiers and tests.'
task :autoclone => [:mkvol, :fill, :clone] do
  devices.reject { |d| DEFAULT_VOLUME_NAME == d.volume.name }.each do |device|
    volume = device.volume
    volume.mount
    puts "===> [verify] #{volume.name}" 
    Rake::Task['verify'].reenable
    Rake::Task['verify'].invoke('/Volumes/'+DEFAULT_VOLUME_NAME, volume.mount_point.to_s)
  end
end

desc "Delete generated files, but leave #{DEFAULT_VOLUME_NAME} intact."
task :clean do
  devices.each { |d| d.detach unless DEFAULT_VOLUME_NAME == d.volume.name }
  begin
    CLEAN.each { |e| run_baby_run('rm', ['-fr', e], :err => '/dev/null') }
  rescue
    CLEAN.each { |e| run_baby_run('chflags', ['-R', 'nouchg', e], :err => '/dev/null', :sudo => true) rescue nil }
    CLEAN.each { |e| run_baby_run('rm', ['-fr', e], :err => '/dev/null', :sudo => true) rescue nil }
  end
end

desc 'Delete all generated products.'
task :clobber => [:detachall, :clean] do
  begin
    CLOBBER.each { |e| run_baby_run('rm', ['-fr', e]) }
  rescue
    puts 'Deleting some files requires administrator privileges'
    puts 'because they are locked and/or have strict permissions.'
    CLOBBER.each { |e| run_baby_run('chflags', ['-R', 'nouchg', e], :sudo => true) }
    CLOBBER.each { |e| run_baby_run('rm', ['-fr', e], :sudo => true) rescue nil }
  end
end

desc <<-EOS
Clone a volume with every enabled copier.

Example:

- To clone /Volumes/#{DEFAULT_VOLUME_NAME} (the default source):

    rake clone

- To clone /Volumes/MyDisk:

    rake clone vol=MyDisk
  or
    rake clone[MyDisk]
EOS
task :clone, [:vol] do |t,args|
  args.with_defaults(:vol => ENV['vol'] || DEFAULT_VOLUME_NAME)
  if args.vol.start_with?('/Volumes/')
    p = Pathname.new(args.vol)
  else
    p = Pathname.new('/Volumes') + args.vol
  end
  abort "#{p} does not exist." unless p.exist?
  # Re-attach the source disk in read-only mode to prevent modification.
  # Make sure that ownership in enabled.
  begin
    device = Rbb::Volume.new(p).parent_whole_disk
  rescue
    abort "Cannot find the disk information for #{p}."
  end
  abort "The source device cannot be a ram disk." if device.ram?
  image_path = Pathname.new(device.image_path)
  abort "#{image_path} does not exist." unless image_path.exist?
  source_disk = Rbb::DiskImage.new(image_path)
  puts "Re-attaching #{image_path.basename} in read-only mode."
  source_disk.reattach(:readonly => true)
  $source = source_disk.device.volume
  unless $source.ownership_enabled?
    puts 'Re-enabling ownership (password may be required)...'
    $source.enable_ownership
  end
  # Load copiers
  $LOAD_PATH.unshift(DIR_COPIERS.to_s)
  $enabled_copiers.each { |c| require c }
  $LOAD_PATH.shift
  # Cloning implemented by files in copiers folder
end

desc <<-EOS
Perform a slow file by file comparison of all the metadata.

By default, this task does not compare inodes and creation times,
since most copiers do not preserve those metadata. You may force
comparing inodes and/or creation times by passing inode=yes and/or
ctime=yes.

Example:

  rake compare src=/Volumes/srcvol dst=/Volumes/dstvol
  rake compare src=~/Desktop/src/timestamps dst=~/Desktop/dst/timestamps ctime=yes

EOS
task :compare, [:src,:dst,:ctime,:inode] do |t,args|
  args.with_defaults(:src => ENV['src'] || '/Volumes/'+DEFAULT_VOLUME_NAME)
  args.with_defaults(:dst => ENV['dst'])
  args.with_defaults(:ctime => ENV['ctime'] || 'no')
  args.with_defaults(:ctime => ENV['inode'] || 'no')
  abort "Please specify a destination." if args.dst.nil?
  source = Pathname.new(args.src).expand_path
  target = Pathname.new(args.dst).expand_path
  abort "#{source} does not exist." unless source.exist?
  abort "#{target} does not exist." unless target.exist?
  ctime = (args.ctime =~ /y/) ? true : false
  inode = (args.inode =~ /y/) ? true : false
  
  require 'ansi/progressbar'
  source_files = Pathname.glob(source + '**' + '**')
  pbar = ::ANSI::Progressbar.new('Testing', source_files.size)

  report = []
  source_files.each do |a|
    pbar.inc
    b = target + a.relative_path_from(source)
    unless b.exist? or b.symlink?
      report << "#{a.relative_path_from(source)}: not copied"
      next
    end
    errors = []
    a_stat = a.lstat
    b_stat = b.lstat
    if inode
      errors << 'inode' if a_stat.ino != b_stat.ino
    end
    errors << 'owner' if a.owner != b.owner
    errors << 'group' if a.group != b.group
    errors << 'permissions' if a_stat.mode != b_stat.mode
    if ctime
      errors << 'creation time' if a.creation_time != b.creation_time
    end
    errors << 'mtime' if a_stat.mtime != b_stat.mtime
    errors << 'BSD flags' if a.bsd_flags != b.bsd_flags
    errors << 'acl' if a.acl != b.acl
    errors << 'file attributes' if a.attributes != b.attributes
    errors << 'Unix file type' if a.file_type != b.file_type
    errors << 'xattrs' if a.extended_attributes != b.extended_attributes
    if a.file?
      errors << 'hard links' if a.num_hardlinks != b.num_hardlinks
      errors << 'creator' if a.creator != b.creator
      errors << 'kind' if a.kind != b.kind
      errors << 'resource forks' if a.derez != b.derez
      errors << 'HFS+ compression' if a.compressed? != b.compressed?
    end
    report << a.relative_path_from(source).to_s + ': ' + errors.join(', ') unless errors.empty?
  end
  pbar.finish
  puts report.join("\n")
end

desc 'List the available copy tasks and their status.'
task :copiers do
  all_copiers = Pathname.glob(DIR_COPIERS+'*.rb').map { |c| c.basename('.rb').to_s }
  $enabled_copiers.each { |c| puts c + ' (enabled)' }
  puts "-" * 20
  (all_copiers - $enabled_copiers).each { |c| puts c + ' (disabled)' }
  puts
  puts "#{all_copiers.size} available, #{$enabled_copiers.size} enabled, " +
    "#{all_copiers.size - $enabled_copiers.size} disabled."
end

desc <<-EOS
Copy the source into the target with every enabled copy task.

The content of the source will be copied into subfolders of the target,
one subfolder for each enabled copy task. Note that some copy tasks can
only clone a whole volume: such tasks will be silently ignored even if
they are enabled.

Example:

- To copy /Volumes/#{DEFAULT_VOLUME_NAME} (the default source)
  into ./#{DIR_TMP.basename} (the default destination):

    rake copy

- To copy /Volumes/#{DEFAULT_VOLUME_NAME} to ~/Desktop/Test:

    rake copy dst=~/Desktop/Test

- To copy ~/Desktop/Src to ~/Dropbox/Dst:

    rake copy src=~/Desktop/Src dst=~/Dropbox/Dst
EOS
task :copy, [:src,:dst] do |t,args|
  abort_if_bsd_system_flags_enabled
  args.with_defaults(:src => ENV['src'] || '/Volumes/'+DEFAULT_VOLUME_NAME)
  args.with_defaults(:dst => ENV['dst'] || DIR_TMP)
  $source = Pathname.new(args.src).expand_path
  $target = Pathname.new(args.dst).expand_path
  abort "#{$source} does not exist." unless $source.exist?
  abort "#{$target} does not exist." unless $target.exist?
  if $source.to_s.start_with?('/Volumes') # Re-mount in read-only mode if necessary
    volume = Rbb::Volume.new($source)
    # Re-mount the source volume in read-only mode to prevent modification.
    # Make sure that ownership in enabled.
    volume.remount(:force_readonly => true) if volume.writable?
    unless volume.ownership_enabled?
      puts 'Re-enabling ownership (password may be required)...'
      volume.enable_ownership
    end
  end
  # Load copiers
  $LOAD_PATH.unshift(DIR_COPIERS.to_s)
  $enabled_copiers.each { |c| require c }
  $LOAD_PATH.shift
  # Copying implemented by files in copiers folder
end

task :default => 'help'

desc <<-EOS
Describe a copy task or test suite.

The argument may be a glob pattern.

Example:

  rake describe[acl]
  rake describe name=dd*
EOS
task :describe, [:name] do |t,args|
  args.with_defaults(:name => ENV['name'])
  Pathname.glob(DIR_COPIERS + (args.name + '.rb')).each do |t|
    if m = t.read.match(/=begin(.*)=end/m)
      puts m[1]
      puts
    else
      puts "No description available for #{t.basename('.rb')}"
    end
  end
  Pathname.glob(DIR_TESTS + (args.name + '.rb')).each do |t|
    if m = t.read.match(/=begin(.*)=end/m)
      puts m[1]
      puts
    else
      puts "No description available for #{t.basename('.rb')}"
    end
  end
end

desc <<-EOS
Detach a device.

The argument may be a dev entry (e.g., /dev/disk4) or a disk image path
(e.g., ./#{DIR_VOLUMES.basename}/#{DEFAULT_VOLUME_NAME}.sparseimage).
To detach a ram disk, you must use a dev entry. Use 'rake disks'
to view the dev entry corresponding to each device.

Example:

- To detach the default source disk image (./#{DIR_VOLUMES.basename}/#{DEFAULT_VOLUME_NAME}.sparseimage):

    rake detach

- To detach a ram disk attached as /dev/disk5:

    rake detach dev=disk5
  or
    rake detach[disk5]
EOS
task :detach, [:dev] do |t,args|
  args.with_defaults(:dev => ENV['dev'] || DIR_VOLUMES+(DEFAULT_VOLUME_NAME+'.sparseimage'))
  p = Pathname.new(args.dev).expand_path
  unless p.exist?
    p = Pathname.new('/dev') + args.dev
    abort "#{args.dev} not found." unless p.exist?
  end
  if p.to_s.start_with?('/dev')
    Rbb::Device.new(args.dev).detach
    puts 'Done.'
  else
    Rbb::DiskImage.new(p).detach
    puts 'Done.'
  end
end

desc 'Detach all the managed disk images and ram disks.'
task :detachall do
  devices.each { |d| d.detach }
end

desc 'A shortcut for disable.'
task :dis, [:name] do |t,args|
  args.with_defaults(:name => ENV['name'])
  Rake::Task['disable'].invoke(args.name)
end
  
desc <<-EOS
Disable a copy task or a test.

The argument may be a glob pattern. You may disable
all the copy tasks or all the tests, respectively, with:

  rake disable[copiers]
  rake disable[tests]

Example:

  rake disable[ditto]
  rake disable name=bsd*flags
EOS
task :disable, [:name] do |t,args|
  args.with_defaults(:name => ENV['name'])
  if args.name =~ /default/i # Enable all default copiers and tests
    cp TXT_DEFAULT_COPIERS, TXT_ENABLED_COPIERS, :verbose => false
    cp TXT_DEFAULT_TESTS, TXT_ENABLED_TESTS, :verbose => false
    puts 'Copiers and tests set to default.'
    exit(0)
  end
  if args.name =~ /copier/i # Disable all copiers
    TXT_ENABLED_COPIERS.write('')
    puts 'All copiers disabled.'
    exit(0)
  end
  if args.name =~ /test/i # Disable all tests
    TXT_ENABLED_TESTS.write('')
    puts 'All tests disabled.'
    exit(0)    
  end
  n = args.name
  disabled_copiers = Pathname.glob(DIR_COPIERS + (args.name+'.rb')).map { |c| c.basename('.rb').to_s }
  $enabled_copiers -= disabled_copiers
  TXT_ENABLED_COPIERS.write($enabled_copiers.join("\n") + "\n")
  disabled_tests = Pathname.glob(DIR_TESTS + (args.name+'.rb')).map { |c| c.basename('.rb').to_s }
  $enabled_tests -= disabled_tests
  TXT_ENABLED_TESTS.write($enabled_tests.join("\n") + "\n")
  Rake::Task['copiers'].invoke unless disabled_copiers.empty?
  Rake::Task['tests'].invoke unless disabled_tests.empty?
end

desc 'List the available disk images and their status.'
task :disks do
  disk_images.each { |d| puts d.pretty_info }
  ram_disks.each { |d| puts d.pretty_info }
end

desc 'A shortcut for enable.'
task :en, [:name] do |t,args|
  args.with_defaults(:name => ENV['name'])
  Rake::Task['enable'].invoke(args.name)
end

desc <<-EOS
Enable a copy task or a test.

The argument may be a glob pattern. You may enable
all the copy tasks, all the tests, or the default
copy tasks and tests, respectively, with:

  rake enable[copiers]
  rake enable[tests]
  rake enable[default]

Example:

  rake enable[dd*]
  rake enable name=acl
EOS
task :enable, [:name] do |t,args|
  args.with_defaults(:name => ENV['name'])
  if args.name =~ /default/i # Enable all default copiers and tests
    cp TXT_DEFAULT_COPIERS, TXT_ENABLED_COPIERS, :verbose => false
    cp TXT_DEFAULT_TESTS, TXT_ENABLED_TESTS, :verbose => false
    puts 'Copiers and tests set to default.'
    exit(0)
  end
  if args.name =~ /copier/i # Enable all copiers
    TXT_ENABLED_COPIERS.write(Pathname.glob(DIR_COPIERS+'*.rb').map { |c| c.basename('.rb') }.join("\n")+"\n")
    puts 'All copiers enabled.'
    exit(0)
  end
  if args.name =~ /test/i # Enable all tests
    TXT_ENABLED_TESTS.write(Pathname.glob(DIR_TESTS+'*.rb').map { |t| t.basename('.rb') }.join("\n")+"\n")
    puts 'All tests enabled.'
    exit(0)    
  end
  n = args.name
  enabled_copiers = Pathname.glob(DIR_COPIERS + (args.name+'.rb')).map { |c| c.basename('.rb').to_s }
  $enabled_copiers |= enabled_copiers
  TXT_ENABLED_COPIERS.write($enabled_copiers.join("\n") + "\n")
  enabled_tests = Pathname.glob(DIR_TESTS + (args.name+'.rb')).map { |c| c.basename('.rb').to_s }
  $enabled_tests |= enabled_tests
  TXT_ENABLED_TESTS.write($enabled_tests.join("\n") + "\n")
  Rake::Task['copiers'].invoke unless enabled_copiers.empty?
  Rake::Task['tests'].invoke unless enabled_tests.empty?
end

desc 'Provide information about the running environment.'
task :env => :version do
  puts 'Ansi ' + Gem.loaded_specs['ansi'].version.to_s
  puts 'MiniTest ' + Gem.loaded_specs['minitest'].version.to_s
  puts 'Plist ' + Gem.loaded_specs['plist'].version.to_s
  puts 'Rake ' + Gem.loaded_specs['rake'].version.to_s
  puts 'Turn ' + Gem.loaded_specs['turn'].version.to_s
  print `sw_vers`
end

desc <<-EOS
Populate the specified path with test data.

Example:

- To populate the default source (/Volumes/#{DEFAULT_VOLUME_NAME}):

    rake fill

- To populate ~/Desktop/MyFolder:

    rake fill[~/Desktop/MyFolder]
  or
    rake fill path=~/Desktop/MyFolder
EOS
task :fill, [:path] do |t,args|
  args.with_defaults(:path => ENV['path'] || '/Volumes/'+DEFAULT_VOLUME_NAME)
  $source = args.path.start_with?('/Volumes') ? Pathname.new(args.path) : Pathname.new('/Volumes')+args.path
  if $source.exist?
    volume = Rbb::Volume.new($source)
    volume.remount unless volume.writable? # Remount in read-write mode if necessary
  elsif $source.to_s =~ /#{DEFAULT_VOLUME_NAME}$/
    Rake::Task['mkvol'].invoke
  else # Assume directory
    abort_if_bsd_system_flags_enabled
    $source = Pathname.new(args.path).expand_path
  end
  abort "#{$source} does not exist." unless $source.exist?
  if Pathname.new(args.path).relative? # ask for confirmation
    puts "Going to populate #{$source}."
    print 'Proceed? '
    abort 'Canceled by user.' unless STDIN.gets.chomp! =~ /y/i
  end
  $target = ''
  # Load fill tasks
  $LOAD_PATH.unshift(DIR_TESTS.to_s)
  $enabled_tests.each { |t| require t }
  $LOAD_PATH.shift
  puts "Populating #{$source} (a password may be required)..."
  # Actions to be defined by test scripts  
end

desc 'Show a short help message and exit.'
task :help do
  puts "Use rake -T [PATTERN] to list the available tasks (matching optional PATTERN)."
  puts "Use rake -D [PATTERN] for a more detailed description."
end

desc <<-EOS
Create a single volume disk image.

The disk image files are always stored inside ./#{DIR_VOLUMES.basename}.

Example:

- To create the default source volume (/Volumes/#{DEFAULT_VOLUME_NAME}):

    rake mkvol
  
- To create a disk image called MyDisk:

    rake mkvol name=MyDisk
  or
    rake mkvol[MyDisk]

- To create a 100M disk image called MyDisk:

    rake mkvol[MyDisk,100M]
  or
    rake mkvol name=MyDisk size=100M
EOS
task :mkvol, [:name, :size] do |t,args|
  args.with_defaults(:name => ENV['name'] || DEFAULT_VOLUME_NAME)
  args.with_defaults(:size => ENV['size'] || DEFAULT_VOLUME_SIZE)
  begin
    Rbb::DiskImage.create args.name, args.size, :dir => DIR_VOLUMES
    puts 'Disk image created.'
  rescue Rbb::DiskImageExists
    puts "Nothing to do, the disk image file exists."
  end
end

if RAM_DISKS_ENABLED
  desc <<-EOS
Create a ram disk.

See 'rake -D mkvol' for the syntax.
EOS
  task :mkram, [:name, :size] do |t,args|
    args.with_defaults(:name => ENV['name'] || DEFAULT_VOLUME_NAME)
    args.with_defaults(:size => ENV['size'] || DEFAULT_VOLUME_SIZE)
    Rbb::RamDisk.create args.name, args.size
    puts 'Ram disk created.'
  end
end

desc <<-EOS
Mount the specified path.

Use 'rake disks' to find the device node for the managed disks.

The volume is mounted in read-write mode by default.
Use rw=no to mount in read-only mode.

Example:

- To mount /dev/disk5s1 in read-only mode:

    rake mount[disk5s1,no]
  or
    rake mount dev=disk5s1 rw=no
EOS
task :mount, [:dev,:rw] do |t,args|
  args.with_defaults(:dev => ENV['dev'] || DEFAULT_VOLUME_NAME)
  args.with_defaults(:rw => ENV['rw'] || 'yes')
  read_only = (args.rw =~ /y/) ? false : true
  if args.dev.start_with?('/dev/')
    p = Pathname.new(args.dev)
  else
    device = device_by_name(args.dev)
    if device.nil?
      p = Pathname.new('/dev') + args.dev
    else
      p = Pathname.new(device.volume.dev_node)
    end
  end
  abort "#{p} is not a valid device entry." unless p.exist?
  Rbb::Volume.new(p).mount(:force_readonly => read_only)
  puts 'Done.'
end

desc <<-EOS
Disable ownership on the given volume.

Disabling ownership requires root privileges, so
this task will prompt for an administrator password.

Example:

- To disable ownership on the default source (/Volumes/#{DEFAULT_VOLUME_NAME}):

    rake noowners

- To disable ownership on /Volumes/MyDisk:

    rake noowners[MyDisk]
  or
    rake noowners vol=MyDisk
EOS
task :noowners, [:vol] do |t,args|
  args.with_defaults(:vol => ENV['vol'] || '/Volumes/'+DEFAULT_VOLUME_NAME)
  if args.vol =~ /^(\/Volumes\/|\/dev\/)/
    p = Pathname.new(args.vol)
  else
    p = Pathname.new('/Volumes') + args.vol
  end
  abort "#{p} is not a valid volume." unless p.exist?
  Rbb::Volume.new(args.vol).disable_ownership
  puts 'Done.'
end

desc <<-EOS
Enable ownership on the given volume.

Enabling ownership requires root privileges, so
this task will prompt for an administrator password.

Example:

- To enable ownership on the default source (/Volumes/#{DEFAULT_VOLUME_NAME}):

    rake owners

- To enable ownership on /Volumes/MyDisk:

    rake owners[/Volumes/MyDisk]
  or
    rake owners vol=/Volumes/MyDisk
EOS
task :owners, [:vol] do |t,args|
  args.with_defaults(:vol => ENV['vol'] || '/Volumes/'+DEFAULT_VOLUME_NAME)
  if args.vol =~ /^(\/Volumes\/|\/dev\/)/
    p = Pathname.new(args.vol)
  else
    p = Pathname.new('/Volumes') + args.vol
  end
  abort "#{p} is not a valid volume." unless p.exist?
  Rbb::Volume.new(args.vol).enable_ownership
  puts 'Done.'
end

desc <<-EOS
Rename a volume.

Example:

  rake rename vol=/Volumes/MyDisk name=NewName
EOS
task :rename, [:vol,:name] do |t,args|
  args.with_defaults(:vol => ENV['vol'] || '/Volumes/'+DEFAULT_VOLUME_NAME)
  args.with_defaults(:name => ENV['name'])
  abort "Please specify a name" if args.name.nil? or args.name.empty?
  if args.vol =~ /^(\/Volumes\/|\/dev\/)/
    p = Pathname.new(args.vol)
  else
    p = Pathname.new('/Volumes') + args.vol
  end
  abort "#{p} is not a valid volume." unless p.exist?
  Rbb::Volume.new(args.vol).rename(args.name)
  puts 'Done.'
end

desc 'List the available tests and their status.'
task :tests do
  all_tests = Pathname.glob(DIR_TESTS+'*.rb').map { |c| c.basename('.rb').to_s }
  $enabled_tests.each { |c| puts c + ' (enabled)' }
  puts "-" * 20
  (all_tests - $enabled_tests).each { |c| puts c + ' (disabled)' }
  puts
  puts "#{all_tests.size} available, #{$enabled_tests.size} enabled, " +
      "#{all_tests.size - $enabled_tests.size} disabled."
end

desc <<-EOS
Unmount the specified volume.

Example:

- To unmount the default source (/Volumes/#{DEFAULT_VOLUME_NAME})

    rake unmount

- To unmount /Volumes/MyDisk:
  
    rake unmount[MyDisk]
  or
    rake unmount vol=MyDisk
EOS
task :unmount, [:vol] do |t,args|
  args.with_defaults(:vol => ENV['vol'] || '/Volumes/'+DEFAULT_VOLUME_NAME)
  if args.vol =~ /^(\/Volumes\/|\/dev\/)/
    p = Pathname.new(args.vol)
  else
    p = Pathname.new('/Volumes') + args.vol
  end
  abort "#{p} is not a valid volume." unless p.exist?
  Rbb::Volume.new(p).unmount
  puts 'Done.'
end

desc <<-EOS
Compare source with target using the given test and format.

Arguments:

  src:    source path (default: /Volumes/#{DEFAULT_VOLUME_NAME})
  dst:    path to a copy of the source
  test:   name of a test case (default: *)
  format: output format (default: pretty)

  The test argument may be a glob pattern. The default is
  to run all the enabled test cases. The values for
  the output format are the same as for the Turn gem:
  pretty, dot, cue, marshal, outline, progress.

Examples:

  rake verify dst=/Volumes/ditto
  rake verify dst=/Volumes/ditto test=*forks
  rake verify src=~/Desktop/MyDir dst=~/Desktop/MyDirCopy format=progress
EOS
task :verify, [:src,:dst,:test,:format] do |t,args|
  args.with_defaults(:src => ENV['src'] || '/Volumes/' + DEFAULT_VOLUME_NAME)
  args.with_defaults(:dst => ENV['dst'])
  args.with_defaults(:test => ENV['test'] || '*')
  args.with_defaults(:format => ENV['format'] || 'pretty')
  $source = Pathname.new(args.src).expand_path
  $target = Pathname.new(args.dst).expand_path
  abort "#{$source} does not exist." unless $source.exist?
  abort "#{$target} does not exist." unless $target.exist?
  # If the source is a volume, make sure it is mounted read-only and ownership is enabled.
  if $source.to_s.start_with?('/Volumes')
    volume = Rbb::Volume.new($source)
    volume.remount(:force_readonly => true)
    unless volume.ownership_enabled?
      puts 'Enabling ownership on the source volume (password may be required)...'
      volume.enable_ownership
    end
  end
  # If the target is a volume, unmount it and remount it
  # (this is needed to make the tests on Spotlight comments more reliable)
  if $target.to_s.start_with?('/Volumes')
    volume = Rbb::Volume.new($target)
    volume.remount(:force_readonly => true)
    unless volume.ownership_enabled?
      puts 'Enabling ownership on the target volume (password may be required)...'
      volume.enable_ownership
    end
  end
  # Load test cases
  $LOAD_PATH.unshift(DIR_TESTS.to_s)
  $enabled_tests.each { |t| require t }
  $LOAD_PATH.shift
  begin
    require 'turn'
  rescue LoadError
    abort "The turn gem was not found. You may need to run 'bundle install'."
  end
  Turn.config.format = args.format.to_sym
  Turn.config.tests = Pathname.glob("tests/#{args.test}.rb") & $enabled_tests.map { |t| Pathname.new('tests')+(t+'.rb') }
  Turn.config.trace = 3
  Turn.config.natural = true
  MiniTest::Unit.runner.run
end

desc 'Print the version of Ruby Backup Bouncer and exit.'
task :version do
  puts Rbb::RBB_USER_AGENT
  puts 'Gleefully brought to you by Lifepillar!'
end

################################################################################

# Documentation
begin
  RDoc::Task.new(:rdoc => "doc", :clobber_rdoc => "doc:clean", :rerdoc => "doc:force") do |rd|
    rd.rdoc_dir = 'doc'
    rd.main = "lib/rbb/rbb.rb"
    rd.rdoc_files.include("lib/**/*.rb")
    rd.title = 'Ruby Backup Bouncer (RBB)'
end
  rescue
end

# Self-tests
namespace :rbb do
  task :selftest do
    system './bin/turn -Ilib -Itest ./test/rbb/test_*.rb'
  end
end
