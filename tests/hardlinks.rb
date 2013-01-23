=begin
Verifies whether hardlinks are preserved or not.
=end

task :fill do
  topdir = $source + 'hardlinks'
  if topdir.exist?
    puts 'Skipping hardlinks (folder exists).'
  else
    puts '===> [fill] hardlinks'
    topdir.mkpath
    # Create some (compressed) files and hardlinks to them
    f1 = topdir + 'file-regular'
    f2 = topdir + 'file-with-inline-data-in-xattr'
    f3 = topdir + 'file-with-compressed-data-in-xattr'
    f4 = topdir + 'file-with-compressed-data-in-resource-fork'
    f1.write_random('1k')
    f2.write_random('4',    :compressed => true)
    f3.write_random('1k',   :compressed => true)
    f4.write_random('100k', :compressed => true)
    # Create hardlinks
    Pathname.glob(topdir + '*').each do |f|
      hl = topdir + ('hardlink-to-' + f.basename.to_s)
      hl.make_link(f)
      hl = topdir + ('hardlink2-to-' + f.basename.to_s)
      hl.make_link(f)
    end
    subdir = topdir+'uchg-hardlinks'
    subdir.mkpath
    f5 = subdir + 'locked-file'
    f5.write_random
    (subdir+'hardlink-to-locked-file').make_link(f5)
    f5.lock
  end
end

#############################################################################
# Tests
#############################################################################

class Hardlinks < Rbb::TestCase
  
  def setup
    set_wd 'hardlinks'
  end

  def test_were_files_copied?
    check_files_copied
  end

  def test_hardlinks_count_on_unlocked_files
    files = Pathname.glob(@src + '*').reject { |f| f.to_s =~ /uchg-hardlinks/ }
    verify_property files do |source,target,name|
      assert_equal source.num_hardlinks, target.num_hardlinks, name
    end
  end
  
  def test_inodes_comparison_on_unlocked_files
    hardlinks = Pathname.glob(@dst + '*').select { |f| f.basename.to_s =~ /^hardlink/ }
    assert hardlinks.size > 0, 'There are no hardlinks on unlocked files in the target'
    hardlinks.each do |hl|
      file = Pathname.new(hl.to_s.sub(/hardlink\d*-to-/, ''))
      assert file.exist?, "#{file} does not exist"
      assert_equal file.inode, hl.inode, hl.basename.to_s
    end
  end

  def test_hardlink_count_on_locked_files
    files = all_files.select { |f| f.file? and f.to_s =~ /uchg-hardlinks/ }
    verify_property files do |source,target,name|
      assert_equal source.num_hardlinks, target.num_hardlinks, name   
    end
  end

  def test_inodes_comparison_on_locked_files
    hardlinks = Pathname.glob(@dst+'uchg-hardlinks'+'*').select { |f| f.basename.to_s =~ /^hardlink/ }
    assert hardlinks.size > 0, 'There are no hardlinks on locked files in the target'
    hardlinks.each do |hl|
      file = Pathname.new(hl.to_s.sub(/hardlink\d*-to-/, ''))
      assert file.exist?, "#{file} does not exist"
      assert_equal file.inode, hl.inode, hl.basename.to_s
    end
  end

  def test_locked_files_are_still_locked
    files = all_files.select { |f| f.file? and f.to_s =~ /uchg-hardlinks/ }
    verify_property files do |source,target,name|
      assert target.locked?, name
    end
  end

end # Hardlinks
