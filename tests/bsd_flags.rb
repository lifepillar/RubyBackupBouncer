=begin
Verifies whether all BSD flags (excluding system flags) are
preserved or not. The test fails if any of the following flags is not
copied correctly: arch, opaque, nodump, uappnd, uchg, and hidden.
=end

task :fill do
  topdir = $source + 'bsd-flags'
  if topdir.exist?
    puts 'Skipping bsd-flags (folder exists).'
  else
    puts '===> [fill] bsd-flags'
    topdir.mkpath
    bsd_flags = ['arch', 'opaque', 'nodump', 'uappnd', 'uchg', 'hidden']
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
    f = topdir + 'file-with-all-bsd-flags'
    d = topdir + 'dir-with-all-bsd-flags'
    f.write_random('1k')
    d.mkpath
    system "sudo chflags #{bsd_flags.join(',')} #{f}"
    system "sudo chflags #{bsd_flags.join(',')} #{d}"    
  end
end

#############################################################################
# Tests
#############################################################################

class BsdFlags < Rbb::TestCase

  def setup
    set_wd 'bsd-flags'
  end

  def verify_bsd_flag keyword
    mask = {
      'sappend' => 01000000, 'schg' => 0400000, 'arch' => 0200000,
      'hidden' => 0100000, 'opaque' => 010, 'uappend' => 04,
      'uchg' => 02, 'nodump' => 01
    }
    n = 0
    verify_property all_files do |source,target,name|
      flag = source.bsd_flags & mask[keyword]
      n += 1 if flag > 0
      assert flag == (target.bsd_flags & mask[keyword]), name
    end
    assert n > 0, "No file in the source has the #{keyword} BSD flag set."
  end

  def test_were_files_copied?
    check_files_copied
  end
   
  def test_bsd_flags
    verify_property all_files do |source,target,name|
      assert_equal source.bsd_flags, target.bsd_flags, name
    end
  end
    
  def test_arch_flag
    verify_bsd_flag('arch')
  end
    
  def test_opaque_flag
    verify_bsd_flag('opaque')
  end
    
  def test_nodump_flag
    verify_bsd_flag('nodump')
  end
    
  def test_uappend_flag
    verify_bsd_flag('uappend')
  end
    
  def test_locked_flag
    verify_bsd_flag('uchg')
  end
    
  def test_hidden_flag
    verify_bsd_flag('hidden')
  end

end # BsdFlags
