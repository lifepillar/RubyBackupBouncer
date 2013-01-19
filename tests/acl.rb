=begin
Verifies whether access control lists are preserved
under several circumstances, including acls on locked files and
directories, and inherited acls.
=end

task :fill do
  topdir = $source + 'acl'
  if topdir.exist?
    puts 'Skipping acl folder (folder exists).'
  else
    puts '===> [fill] acl'
    topdir.mkpath
    locked = [false,true]
    acl = ['delete', 'readattr', 'writeattr', 'readextattr', 'writeextattr',
           'readsecurity', 'writesecurity', 'chown']
    diracl = ['list', 'search', 'add_file', 'add_subdirectory', 'delete_child',
             'file_inherit', 'directory_inherit', 'limit_inherit', 'only_inherit']
    nondiracl = ['read', 'write', 'append', 'execute']
    aclinheritance = ['file_inherit', 'directory_inherit', 'limit_inherit', 'only_inherit']

    # Create locked and unlocked files and directories for each permission.
    locked.each do |is_locked|
      l = is_locked ? '-locked' : ''
      acl.each do |p|
        f = topdir + ('file-with-' + p + l)
        d = topdir + ('dir-with-'  + p + l)
        f.write_random('1k')
        d.mkpath
        system "chmod +a \"nobody allow #{p}\" #{f} #{d}"
        system "chflags uchg #{f} #{d}" if is_locked
      end

      # Create a file and a directory with all generic permissions.
      f = topdir + ('file-with-all-generic-acl' + l)
      d = topdir + ('dir-with-all-generic-acl'  + l)
      f.write_random('1k')
      d.mkpath
      system "chmod +a \"nobody allow #{acl.join(',')}\" #{f} #{d}"
      system "chflags uchg #{f} #{d}" if is_locked
      
      # Do the same for ACLs that are specific to directories
      diracl.each do |p|
        d = topdir + ('dir-with-' + p + l)
        d.mkpath
        system "chmod +a \"nobody allow #{p}\" #{d}"
        system "chflags uchg #{d}" if is_locked
      end
      
      # Create a directory with all permissions for directories.
      d = topdir + ('dir-with-all-acl-for-directories' + l)
      d.mkpath
      system "chmod +a \"nobody allow #{diracl.join(',')}\" #{d}"
      system "chflags uchg #{d}" if is_locked
      
      # Do the same for ACLs for non-directory objects
      nondiracl.each do |p|
        f = topdir + ('file-with-' + p + l)
        f.write_random('1k')
        system "chmod +a \"nobody allow #{p}\" #{f}"
        system "chflags uchg #{f}" if is_locked
      end
      f = topdir + ('file-with-all-acl-for-non-directories' + l)
      f.write_random('1k')
      system "chmod +a \"nobody allow #{nondiracl.join(',')}\" #{f}"
      system "chflags uchg #{f}" if is_locked

      # Create some objects to test ACL inheritance
      d = topdir + ('inherited-acls' + l)
      d.mkpath
      f = d + ('file-created-before-inherited-acl-applied' + l)
      f.write_random('1k')
      system "chflags uchg #{f}" if is_locked
      # Apply ACLs
      system "chmod +a \"www allow read\" #{d}"
      system "chmod +a \"nobody allow read\" #{d}"
      system "chmod +a \"nobody allow read\" #{d}"
      system "chmod +a \"staff allow list,directory_inherit,file_inherit\" #{d}"
      f = d + ('file-created-after-inherited-acl-applied' + l)
      f.write_random('1k')
      system "chflags uchg #{f}" if is_locked
    end
  end
end

#############################################################################
# Tests
#############################################################################

class AccessControlLists < Rbb::TestCase

  def setup
    set_wd 'acl'
  end

  def test_were_files_copied?
    check_files_copied
  end

  def test_acl_on_unlocked_files
    files = all_files.select { |f| f.file? and (not f.symlink?) and (not f.locked?) }
    assert files.size > 0, "There is no unlocked file in #{@src}"
    verify_property files do |source,target,name|
      assert_equal source.acl, target.acl, name
    end
  end

  def test_acl_on_locked_files
    files = all_files.select { |f| f.file? and (not f.symlink?) and f.locked? }
    assert files.size > 0, "There is no locked file in #{@src}"
    verify_property files do |source,target,name|
      assert_equal source.acl, target.acl, name
    end
  end
  
   def test_acl_on_unlocked_directories
     dirs = all_directories.select { |f| not f.locked? }
     assert dirs.size > 0, "There is no unlocked directory in #{@src}"
     verify_property dirs do |source,target,name|
       assert_equal source.acl, target.acl, name
     end
   end
  
   def test_acl_on_locked_directories
     dirs = all_directories.select { |f| f.locked? }
     assert dirs.size > 0, "There is no locked directory in #{@src}"
     verify_property dirs do |source,target,name|
       assert_equal source.acl, target.acl, name
     end
   end
   
   def test_inherited_access_control_lists
     verify_property Pathname.glob(@src + 'inherited-acls' + '*') do |source,target,name|
       assert_equal source.acl, target.acl, name
     end
     verify_property Pathname.glob(@src + 'inherited-acls-locked' + '*') do |source,target,name|
       assert_equal source.acl, target.acl, name
     end
   end
end # AccessControlLists
