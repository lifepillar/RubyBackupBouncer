=begin
Verifies whether file creator, file type and file attributes
are preserved or not.
=end

task :fill do
  topdir = $source + 'file-attributes'
  if topdir.exist?
    puts 'Skipping file-attributes (folder exists).'
  else
    puts '===> [fill] file-attributes'
    topdir.mkpath
    flags = ['A', 'B', 'C', 'D', 'E', 'I', 'L', 'M', 'N', 'S', 'T', 'V', 'Z']
    folderflags = ['C', 'D', 'E', 'I', 'V', 'Z']
    # For each attribute, create a file with only that attribute set
    flags.each do |flag|
      f = topdir + ('file-with-attribute-' + flag)
      f.write_random('1k')
      system "sudo SetFile -P -a #{flag} #{f}"
    end
    # Create a file with all the attributes on
    f = topdir + 'file-with-all-flags'
    f.write_random('1k')
    system "sudo SetFile -P -a #{flags.join} #{f}"
    # Create a file with all the attributes on, but the locked attribute
    f = topdir + 'file-with-all-flags-not-locked'
    f.write_random('1k')
    system "sudo SetFile -P -a ABCDEIMNSTVZ #{f}"
    # Create a file with all the attributes on, but the locked attribute
    # Then lock it
    f = topdir + 'file-with-all-flags-uchg'
    f.write_random('1k')
    system "sudo SetFile -P -a ABCDEIMNSTVZ #{f}"
    system "sudo chflags uchg #{f}"
    # For each folder attribute, make a folder with only that attribute set
    folderflags.each do |flag|
      f = topdir + 'dir-with-attribute-' + flag
      f.mkpath
      system "sudo SetFile -P -a #{flag} #{f}"
    end
    # Create a folder with all the attributes set
    f = topdir + 'dir-with-all-flags'
    f.mkpath
    system "sudo SetFile -P -a #{folderflags.join} #{f}"
    # For each combination of type and creator, create a new file
    types = ['0','TEXT','bzy ']
    creators = ['0', 'RBBo']
    types.each do |t|
      creators.each do |c|
        f = topdir + ('file-with-type-' + t.strip + '-and-creator-' + c)
        f.write_random('1k')
        system "SetFile -P -c '#{c}' -t '#{t}' #{f}"
      end
    end
    # Create an alias
    aliased = topdir + 'file-with-alias'
    aliased.write_random('1k')
    (topdir + 'alias-to-file-with-alias').make_alias(aliased)
  end
end

#############################################################################
# Tests
#############################################################################

class FileAttributes < Rbb::TestCase
  
  def setup
    set_wd 'file-attributes'
  end

  def verify_flag(letter)
    n = 0
    verify_property all_files do |source,target,name|
      flag = source.attribute?(letter)
      n += 1 if flag
      assert_equal source.attribute?(letter), target.attribute?(letter),
        "The #{letter.upcase} flag is not preserved by #{name}"
    end
    assert n > 0, "There is no file in the source having the #{letter.upcase} flag set."
  end

  def test_were_files_copied?
    check_files_copied
  end
   
  def test_file_attributes
    verify_property all_files do |source,target,name|
      assert_equal source.attributes, target.attributes, name
    end
  end
  
  def test_file_creator
    files = all_files.reject { |f| f.directory? }
    verify_property files do |source,target,name|
      assert_equal source.creator, target.creator, name
    end
  end
  
  def test_file_type
    files = all_files.reject { |f| f.directory? }
    verify_property files do |source,target,name|
      assert_equal source.kind, target.kind, name
    end
  end
    
  def test_alias_file_flag
    verify_flag('a')
  end
  
  def test_has_bundle_flag
    verify_flag('b')
  end
    
  def test_custom_icon_flag
    verify_flag('c')
  end
    
  def test_located_on_desktop_flag
    verify_flag('d')
  end
    
  def test_hidden_extension_flag
    verify_flag('e')
  end
    
  def test_inited_flag
    verify_flag('i')
  end
    
  def test_locked_flag
    verify_flag('l')
  end
    
  def test_shared_flag
    verify_flag('m')
  end
    
  def test_no_INIT_resource_flag
    verify_flag('n')
  end
    
  def test_system_file_flag
    verify_flag('s')
  end
    
  def test_stationery_pad_flag
    verify_flag('t')
  end
    
  def test_invisible_flag
    verify_flag('v')
  end
    
  def test_busy_flag
    verify_flag('z')
  end

end # FileAttributes
