=begin
Verifies whether creation and modification dates are
preserved on files and directories (even when locked and/or with
extended attributes), on hardlinks and on symlinks.
=end

task :fill do
  topdir = $source + 'timestamps'
  if topdir.exist?
    puts 'Skipping timestamps (folder exists).'
  else
    puts '===> [fill] timestamps'
    topdir.mkpath
    atime = Time.utc(2001, 'jul', 16, 20, 15, 1)
    mtime = Time.utc(1999, 'feb', 14, 8, 58, 57)
    f   = topdir + 'file-regular'
    fe  = topdir + 'file-with-extended-attributes'
    fel = topdir + 'file-with-extended-attributes-locked'
    fc1 = topdir + 'file-with-inline-data-in-xattr'
    fc2 = topdir + 'file-with-compressed-data-in-xattr'
    fc3 = topdir + 'file-with-compressed-data-in-resource-fork'
    d   = topdir + 'dir-regular'
    de  = topdir + 'dir-with-extended-attributes'
    del = topdir + 'dir-with-extended-attributes-locked'
    hl  = topdir + 'hardlink-to-file'
    sl1 = topdir + 'symlink-to-file'
    sl2 = topdir + 'symlink-to-dir'
    f.write_random('1k')
    fe.write_random('1k')
    fel.write_random('1k')
    fe.set_xattr('some.random.string', random_string(1024))
    fel.set_xattr('some.random.string', random_string(1024))
    fc1.write_random('4')
    fc2.write_random('1k')
    fc3.write_random('100k')
    d.mkpath
    de.mkpath
    del.mkpath
    de.set_xattr('some.random.string', random_string(1024))
    del.set_xattr('some.random.string', random_string(1024))
    hl.make_link(f)
    sl1.make_symlink(f)
    sl2.make_symlink(d)
    # Set last access and modification times
    File.utime(atime, mtime, f, fe, fel, fc1, fc2, fc3, d, de, del, hl)
    system "SetFile -P -m '11/4/1999 16:00:30 AM' #{sl1}"
    system "SetFile -P -m '11/4/1999 17:00:20 AM' #{sl2}"
    # Set creation dates
    system "SetFile -P -d '10/1/1997 07:15:32 PM' #{f} #{fe} #{fel} #{fc1} #{fc2} #{fc3}"
    system "SetFile -P -d '11/1/1997 09:18:28 PM' #{d} #{de} #{del}"
    system "SetFile -P -d '12/1/1997 11:12:13 AM' #{sl1}"
    system "SetFile -P -d '12/1/1997 11:44:00 AM' #{sl2}"
    # Lock a file and a directory
    system "chflags uchg #{fel} #{del}"
  end
end


#############################################################################
# Tests
#############################################################################

class Timestamps < Rbb::TestCase
  
  def setup
    set_wd 'timestamps'
  end

  def test_files_copied?
    check_files_copied
  end
  
  def test_creation_date
    files = all_files.reject { |f| f.symlink? }
    verify_property files do |source,target,name|
      assert_equal source.creation_time, target.creation_time, name
    end
  end
  
  def test_creation_date_on_symlinks
    verify_property all_symlinks do |source,target,name|
      assert_equal source.creation_time, target.creation_time, name
    end
  end

  def test_mtime
    files = all_files.reject { |f| f.symlink? }
    verify_property files do |source,target,name|
      assert_equal source.mtime, target.mtime,
        "stat.mtime has reported different modification times for #{name}"
    end
  end

  def test_mtime_on_symlinks
    verify_property all_symlinks do |source,target,name|
      assert_equal File.lstat(source.to_s).mtime, File.lstat(target.to_s).mtime,
        "lstat.mtime has reported different modification times for symlink #{name}"
    end
  end

  def test_modification_date
    files = all_files.reject { |f| f.symlink? }
    verify_property files do |source,target,name|
      assert_equal source.modification_time, target.modification_time,
        "GetFileInfo has reported different modification times for #{name}"
    end
  end

  def test_modification_date_on_symlinks
    verify_property all_symlinks do |source,target,name|
      assert_equal source.modification_time, target.modification_time,
        "GetFileInfo has reported different modification times for symlink #{name}"
    end
  end

end # Timestamps
