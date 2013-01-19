=begin
Verifies the two system BSD flags schg and sappnd.

NOTE: in general, those two flags can be unset only when the system is
booted in single-user mode. It should be possible, however, to unset
those flags for files or directories that reside on disk images. It is
therefore recommended to enable this test *only* when cloning and
*not* when copying into a folder in the startup disk.
=end

task :fill do
  topdir = $source + 'bsd-system-flags'
  if topdir.exist?
    puts 'Skipping bsd-system-flags (folder exists).'
  else
    puts "*" * 78
    puts "  READ CAREFULLY!"
    puts "*" * 78
    puts 'I am going to create some files and set some system BSD flags for them.'
    puts 'In general, such flags can only be unset when the system is booted'
    puts 'in single-user mode (by pressing cmd-S after the startup chime),'
    puts 'by typing commands similar to the following:'
    puts
    puts '  /sbin/mount -wu /'
    puts '  cd /path/to/my/dir'
    puts '  chflags -R nosappnd ./'
    puts '  chflags -R noschg ./'
    puts '  reboot'
    puts
    puts 'If you are only cloning volumes (for example, by running the autoclone task),'
    puts 'it is safe to proceed, because those volumes can be safely deleted later on.'
    puts "*" * 78
    puts "The path to populate is #{$source}."
    puts 'Should I proceed? (Type YES to proceed)'
    answer = STDIN.gets.chomp!
    abort "Task interrupted." unless answer.eql?('YES')

    puts '===> [fill] bsd-system-flags'
    topdir.mkpath
    bsd_flags = ['schg', 'sappend']
    # Create a file and a directory for each flag
    bsd_flags.each do |flag|
      f = topdir + ('file-with-bsd-flag-' + flag)
      d = topdir + ('dir-with-bsd-flag-' + flag)
      f.write_random('1k')
      d.mkpath
      system "sudo chflags #{flag} #{f}"
      system "sudo chflags #{flag} #{d}"
    end
    # Create a file and a directory with all the flags enabled
    f = topdir + 'file-with-all-system-bsd-flags'
    d = topdir + 'dir-with-all-system-bsd-flags'
    f.write_random('1k')
    d.mkpath
    system "sudo chflags #{bsd_flags.join(',')} #{f}"
    system "sudo chflags #{bsd_flags.join(',')} #{d}"    
  end
end

#############################################################################
# Tests
#############################################################################

class BSDSystemFlags < Rbb::TestCase
  
  def setup
    set_wd 'bsd-system-flags'
  end

  def verify_system_bsd_flag keyword
    mask = { 'sappend' => 01000000, 'schg' => 0400000 }
    n = 0
    verify_property all_files do |source,target,name|
      flag = source.bsd_flags & mask[keyword]
      n += 1 if flag > 0
      assert flag == (target.bsd_flags & mask[keyword]), name
    end
    assert n > 0, "No file in the source has the #{keyword} BSD flag set."
  end

  def test_files_copied?
    check_files_copied
  end
  
  def test_sappend_flag
    verify_system_bsd_flag('sappend')
  end
  
  def test_schg_flag
    verify_system_bsd_flag('schg')
  end
end
