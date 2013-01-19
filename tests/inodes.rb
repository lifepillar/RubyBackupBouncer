=begin
Verifies whether inodes are preserved.
=end

task :fill do
  topdir = $source + 'inodes'
  if topdir.exist?
    puts 'Skipping inodes (folder exists).'
  else
    puts '===> [fill] inodes'
    topdir.mkpath
    f1 = topdir + 'file-regular'
    d = topdir + 'dir-regular'
    f1.write_random('1k')
    d.mkpath
    sl = topdir + 'symlink-to-file'
    sl.make_symlink(f1)
    hl = topdir + 'hardlink-to-file'
    hl.make_link(f1)
    al = topdir + 'alias-to-dir'
    al.make_alias(d)
  end
end

#############################################################################
# Tests
#############################################################################

class Inodes < Rbb::TestCase
  
  def setup
    set_wd 'inodes'    
  end
  
  def test_files_copied?
    check_files_copied
  end
  
  def test_inodes
    verify_property all_files do |source,target,name|
      assert_equal source.inode, target.inode, name
    end
  end

end # Inodes
