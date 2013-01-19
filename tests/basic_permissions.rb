=begin
Performs a thorough check of permissions on files,
directories, symlinks and hardlinks. It checks whether
owners, groups and Unix permissions (including setuid, setgid and
sticky flags) are preserved.
=end

task :fill do
  topdir = $source + 'basic-permissions'
  if topdir.exist?
    puts 'Skipping basic permissions (folder exists).'
  else
    puts '===> [fill] basic-permissions'
    topdir.mkpath
    owners = [Process.euid, 'root', '_www', 666] # 666 = most probably non-existent
    groups = ['admin', 'staff','_www', 666]
    permissions = [0740,01777,06711,04501,02540]
    # For every combination of owner, group and set of permissions,
    # create a file, a directory, and a hard link
    owners.each do |o|
      groups.each do |g|
        permissions.each do |p|
          suffix = o.to_s + g.to_s + p.to_s
          # Create file
          f = topdir + ('file-' + suffix)
          f.write_random
          # Create hardlink
          (topdir + ('hardlink-' + suffix)).make_link(f)
          system "sudo chown #{o} #{f}"
          system "sudo chgrp #{g} #{f}"
          system 'sudo chmod ' + sprintf('%o',p) + " #{f}"
          # Create directory
          d = topdir + ('dir-' + suffix)
          d.mkpath
          system "sudo chown #{o} #{d}"
          system "sudo chgrp #{g} #{d}"
          system 'sudo chmod ' + sprintf('%o',p) + " #{d}"
          # Create symlinks
          l = topdir + ('symlink-' + suffix)
          l.make_symlink(f)
          system "sudo chown -h #{o} #{l}"
          system "sudo chgrp -h #{g} #{l}"
          # Create link to symlink
          ll = topdir + ('symlink-symlink-' + suffix)
          ll.make_symlink(l)
          system "sudo chown -h nobody #{ll}"
          system "sudo chgrp -h nobody #{ll}"
        end
      end
    end
    # It seems that Apple's rsync 2.6.9 screws everything in the presence of
    # hardlinked files with resource forks
    f = topdir + ('file-with-resource-fork-hardlinked')
    rsrc = <<EOS
resource 'STR#' (128, "Test Resource Fork") {
  {  "KEY=value" };
};
EOS
    f.write_random('1k', :rsrc => rsrc)
    (topdir + 'hardlink-to-file-with-resource-fork').make_link(f)
  end
end

#############################################################################
# Tests
#############################################################################

class BasicPermissions < Rbb::TestCase

  def setup
    set_wd 'basic-permissions'
  end
  
  def test_were_files_copied?
    check_files_copied
  end

  def test_owners
    verify_property all_files do |source,target,name|
      assert_equal source.stat.uid, target.stat.uid, name
    end
  end
  
  def test_groups
    verify_property all_files do |source,target,name|
      assert_equal source.stat.gid, target.stat.gid, name
    end
  end
  
  def test_permissions
    verify_property all_files do |source,target,name|
      assert_equal source.permissions, target.permissions, name
    end
  end
  
  def test_stickiness
    verify_property all_files do |source,target,name|
      assert_equal source.stat.sticky?, target.stat.sticky?, name
    end
  end
  
  def test_setuid
    verify_property all_files do |source,target,name|
      assert_equal source.stat.setuid?, target.stat.setuid?, name
    end
  end
  
  def test_setgid
    verify_property all_files do |source,target,name|
      assert_equal source.stat.setgid?, target.stat.setgid?, name
    end
  end
  
  def test_symlinks_owners
    verify_property all_symlinks do |source,target,name|
      assert_equal source.lstat.uid, target.lstat.uid, name
    end
  end
  
  def test_symlinks_groups
    verify_property all_symlinks do |source,target,name|
      assert_equal source.lstat.gid, target.lstat.gid, name
    end
  end

end # BasicPermissions
