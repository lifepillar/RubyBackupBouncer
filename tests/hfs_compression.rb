=begin
Verifies whether HFS+ compression is preserved. It
checks whether the compression is maintained for files with inline
data in the com.apple.decmpfs extended attribute (very small files),
for files with compressed data in the com.apple.decmpfs extended
attribute (small files) and for files with compressed data in the
resource fork (big files).
=end

task :fill do
  topdir = $source + 'hfs_compression'
  if topdir.exist?
    puts 'Skipping hfs_compression (folder exists).'
  else
    puts '===> [fill] hfs_compression'
    topdir.mkpath
    f1 = topdir + 'file-with-inline-data-in-xattr'
    f2 = topdir + 'file-with-compressed-data-in-xattr'
    f3 = topdir + 'file-with-compressed-data-in-resource-fork'
    f1.write_random('4',    :compressed => true) # Compression method: xattr inline
    f2.write_random('1k',   :compressed => true) # Compression method: xattr compressed
    f3.write_random('100k', :compressed => true) # Compression method: resource fork compressed
    # Create hardlinks to the previous files
    (topdir + ('hardlink-' + f1.basename.to_s)).make_link(f1)
    (topdir + ('hardlink-' + f2.basename.to_s)).make_link(f2)
    (topdir + ('hardlink-' + f3.basename.to_s)).make_link(f3)
  end
end

#############################################################################
# Tests
#############################################################################

class HFSPlusCompression < Rbb::TestCase
  
  def setup
    set_wd 'hfs_compression'
  end
  
  def test_were_files_copied?
    check_files_copied
  end

  def test_compression_is_preserved
    n = 0
    verify_property all_files do |source,target,name|
      assert source.compressed?, name
      assert target.compressed?, name
      decmpfs_src = source.xattr('com.apple.decmpfs')
      refute_equal decmpfs_src, '', name
      assert decmpfs_src == target.xattr('com.apple.decmpfs'), name
      rsrc_src = source.xattr('com.apple.ResourceFork')
      unless rsrc_src.nil?
        n += 1
        assert rsrc_src == target.xattr('com.apple.ResourceFork'), name
      end
      assert n > 0, "There are no files in the source whose resource fork contains compressed data"
    end
  end

  def test_inline_compression
    source = @src + 'file-with-inline-data-in-xattr'
    target = @dst + source.relative_path_from(@src)
    refute_nil source.xattr('com.apple.decmpfs'), "#{source.basename} is supposed to have com.apple.decmpfs"
    assert source.xattr('com.apple.decmpfs') == target.xattr('com.apple.decmpfs'), source.basename.to_s
  end

  def test_compressed_in_extended_attribute
    source = @src + 'file-with-compressed-data-in-xattr'
    target = @dst + source.relative_path_from(@src)
    refute_nil source.xattr('com.apple.decmpfs'), "#{source.basename} is supposed to have com.apple.decmpfs"
    assert source.xattr('com.apple.decmpfs') == target.xattr('com.apple.decmpfs'), source.basename.to_s
  end

  def test_compressed_in_resource_fork
    source = @src + 'file-with-compressed-data-in-resource-fork'
    target = @dst + source.relative_path_from(@src)
    refute_nil source.xattr('com.apple.decmpfs'), "#{source.basename} is supposed to have com.apple.decmpfs"
    assert source.xattr('com.apple.decmpfs') == target.xattr('com.apple.decmpfs'), source.basename.to_s
    refute_nil source.xattr('com.apple.ResourceFork'), "#{source.basename} is supposed to have a resource fork"
    assert source.xattr('com.apple.ResourceFork') == target.xattr('com.apple.ResourceFork'), source.basename.to_s
  end

  def test_inline_compression_hardlink
    source = @src + 'hardlink-file-with-inline-data-in-xattr'
    target = @dst + source.relative_path_from(@src)
    refute_nil source.xattr('com.apple.decmpfs'), "#{source.basename} is supposed to have com.apple.decmpfs"
    assert source.xattr('com.apple.decmpfs') == target.xattr('com.apple.decmpfs'), source.basename.to_s
  end

  def test_compressed_in_extended_attribute_hardlink
    source = @src + 'hardlink-file-with-compressed-data-in-xattr'
    target = @dst + source.relative_path_from(@src)
    refute_nil source.xattr('com.apple.decmpfs'), "#{source.basename} is supposed to have com.apple.decmpfs"
    assert source.xattr('com.apple.decmpfs') == target.xattr('com.apple.decmpfs'), source.basename.to_s
  end

  def test_compressed_in_resource_fork_hardlink
    source = @src + 'hardlink-file-with-compressed-data-in-resource-fork'
    target = @dst + source.relative_path_from(@src)
    refute_nil source.xattr('com.apple.decmpfs'), "#{source.basename} is supposed to have com.apple.decmpfs"
    assert source.xattr('com.apple.decmpfs') == target.xattr('com.apple.decmpfs'), source.basename.to_s
    refute_nil source.xattr('com.apple.ResourceFork'), "#{source.basename} is supposed to have a resource fork"
    assert source.xattr('com.apple.ResourceFork') == target.xattr('com.apple.ResourceFork'), source.basename.to_s
  end

  def test_data_content_is_preserved
    files = all_files.select { |f| not f.directory? and not f.symlink? }
    verify_property files do |source,target,name|
      assert_equal source.md5, target.md5, name
      assert source.compare(target), name
    end
  end
  
  def test_uncompressed_file_size_is_the_same
    verify_property all_files do |source,target,name|
      assert_equal source.size, target.size, name
    end
  end

end # HFSPlusCompression
