# -*- coding: utf-8 -*-

# Copyright (c) 2012 Lifepillar
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
require 'helper'

class TestPathname < MiniTest::Unit::TestCase

  def setup
    @tmpdir = Pathname.tempdir
    @pp = Pathname.new(@tmpdir + 'somefile')
    @pp.write('abcde')
    @sl = Pathname.new(@tmpdir + 'symlink')
    @sl.make_symlink(@pp) # Symlink to @pp
    @hl = Pathname.new(@tmpdir + 'hardlink')
    @hl.make_link(@pp)
  end

  def teardown
    system "chflags nouchg '#{@pp}'"
    @tmpdir.rmtree
  end

  def test_inode
    assert_equal File.lstat(@pp.to_s).ino, @pp.inode
    assert_equal File.lstat(@sl).ino, @sl.inode
    refute_equal @pp.inode, @sl.inode
    assert_equal @pp.inode, @hl.inode
  end

  def test_permissions_on_symlinks
    refute_equal @pp.permissions, @sl.permissions,
      'Permission on symlinks should be different'
  end

  def test_hardlink_count
    assert_equal 2, @pp.num_hardlinks, "Wrong number of hard links for #{@pp}"
    assert_equal 1, @sl.num_hardlinks, "Wrong number of hard links for #{@sl}"
    assert_equal 2, @hl.num_hardlinks, "Wrong number of hard links for #{@hl}"
  end

  def test_readlink
    assert_equal @pp, @sl.readlink 
  end

  def test_symlink_size
    assert_equal @pp.size, @sl.size # #size resolves symlinks
    refute_equal @pp.lsize, @sl.lsize
  end

  def test_symlink_blocks
    @pp.write("a" * 16384) # Make the file bigger
    assert_equal @pp.blocks, @hl.blocks, 'Hard link not matching block size of file'
    refute_equal @pp.blocks, @sl.blocks
  end

  # Checks that Pathname#mtime and GetFileInfo report the same value.
  def test_mtime_compatible_with_GetFileInfo
    d1 = `GetFileInfo -P -m '#{@pp}'`
    match = d1.match(/^(\d+)\/(\d+)\/(\d+)\s+(\d+):(\d+):(\d+)/)
    mon = match[1].to_i
    day = match[2].to_i
    year = match[3].to_i
    hh = match[4].to_i
    mm = match[5].to_i
    ss = match[6].to_i
    d2 = @pp.mtime
    assert_equal year, d2.year, 'Years differ'
    assert_equal mon,  d2.month, 'Months differ'
    assert_equal day,  d2.day, 'Days differ'
    assert_equal hh,   d2.hour, 'Hours differ'
    assert_equal mm,   d2.min, 'Minutes differ'
    assert_equal ss,   d2.sec, 'Seconds differ'
  end

  def test_creation_time
    @pp.creation_time = '10/18/2012 06:34:55 PM'
    @sl.creation_time = '09/18/2012 06:34:55 AM'
    c1 = @pp.creation_time
    c2 = @sl.creation_time
    c3 = @hl.creation_time
    assert_equal '10/18/2012 18:34:55', c1
    assert_equal '09/18/2012 06:34:55', c2
    assert_equal c1, c3, 'A file and its hardlinks should have the same creation time'
  end

  def test_modification_time
    @pp.modification_time = '10/18/2012 11:26:09 PM'
    @sl.modification_time = '10/18/2012 11:16:21 AM'
    m1 = @pp.modification_time
    m2 = @sl.modification_time
    m3 = @hl.modification_time
    assert_equal '10/18/2012 23:26:09', m1
    assert_equal '10/18/2012 11:16:21', m2
    assert_equal m1, m3, 'A file and its hardlinks should have the same modification time'
  end

  def test_attributes
    assert_equal @pp.attributes, @hl.attributes
    refute_equal @pp.attributes, @sl.attributes
    assert_match(/^a/, @pp.attributes)
    assert_match(/^A/, @sl.attributes)
  end

  def test_attribute?
    refute @pp.attribute? 'a' # alias?
    refute @pp.attribute? 'v' # hidden?
    assert @sl.attribute? 'a'
  end

  def test_creator
    @pp.creator = 'You '
    # In OS X Lion (at least), it does not seem possible to change the creator
    # of a symlink.
    #@sl.creator = 'MsLf'
    c1 = @pp.creator
    c2 = @sl.creator
    assert_equal 'You ', @pp.creator, 'Incorrect creator for file'
    assert_equal 'rhap', @sl.creator, 'Creator for symlink should be "rhap"'
  end

  def test_kind
    @pp.kind = 'LuMp'
    # In OS X Lion (at least), it does not seem possible to change the type
    # of a symlink.
    #@sl.kind = 'Lnk '
    k1 = @pp.kind
    k2 = @sl.kind
    k3 = @hl.kind
    assert_instance_of String, k1
    assert_equal "LuMp", k1, "Unexpected type: #{k1}"
    assert_equal "slnk", k2, "Unexpected type: #{k2}"
    assert_equal  k1, k3, "Unexpected type: #{k3}"
  end

  def test_set_and_get_extended_attributes_on_file
    assert_equal [], @pp.extended_attributes, 'The file should not have xattrs'
    @pp.set_xattr 'com.lifepillar.CustomAttr', 'Here I am!'
    assert_equal ['com.lifepillar.CustomAttr'], @pp.extended_attributes
    assert_equal 'Here I am!', @pp.xattr('com.lifepillar.CustomAttr')
    assert_equal ['com.lifepillar.CustomAttr'], @hl.extended_attributes, 'Xattrs not set on hardlink'
    assert_equal 'Here I am!', @hl.xattr('com.lifepillar.CustomAttr'), 'Xattr value not set on hardlink'
  end

  def test_set_and_get_extended_attributes_on_symlink
    assert_equal [], @pp.extended_attributes, 'The file should not have xattrs'
    assert_equal [], @sl.extended_attributes, 'The symlink should not have xattrs'
    assert_equal [], @hl.extended_attributes, 'The hardlink should not have xattrs'
    @sl.set_xattr 'com.lifepillar.SymAttr', 'I am with a symlink'
    assert_equal ['com.lifepillar.SymAttr'], @sl.extended_attributes
    assert_equal 'I am with a symlink', @sl.xattr('com.lifepillar.SymAttr')
    assert_equal [], @pp.extended_attributes, 'The file should still be without xattrs'
    assert_equal [], @hl.extended_attributes, 'The hardlink should still be without xattrs'
  end

  # The following are methods already existing in Pathname

  def test_setuid?
    assert_equal File.stat(@pp.to_s).setuid?, @pp.setuid?
  end

  def test_setgid?
    assert_equal File.stat(@pp.to_s).setgid?, @pp.setgid?
  end

  def test_sticky?
    assert_equal File.stat(@pp.to_s).sticky?, @pp.sticky?
  end

  def test_lock_unlock
    refute @pp.locked?, 'File should be unlocked'
    @pp.lock
    assert @pp.locked?, 'Now the file should be locked'
    @pp.unlock
    refute @pp.locked?, 'File should be unlocked again'
  end

end # TestPathname

class TestHfsCompressionWithDitto < MiniTest::Unit::TestCase

  def setup
    @tmpdir = Pathname.tempdir
    @pp = Pathname.new(@tmpdir + 'somefile')
    @pp.write('abcde')
    @cp = Pathname.new(@tmpdir + 'compressedfile')
    system("ditto --hfsCompression #{@pp} #{@cp}")
  end

  def teardown
    @tmpdir.rmtree
  end

  def test_compressed?
    refute @pp.compressed?, "#{@pp} should not use HFS compression"
    refute_match(/compressed/, `ls -lO #{@pp}`) # Another way to check for compressed files
    assert @cp.compressed?, "#{@cp} should use HFS compression"
    assert_match(/compressed/, `ls -lO #{@cp}`)
  end

end # TestHfsCompression

class TestAliases < MiniTest::Unit::TestCase

  def setup
    @tmpdir = Pathname.tempdir
    @pp = Pathname.new(@tmpdir + 'somefile')
    @pp.write('abcde')
    @ap = Pathname.new(@tmpdir + 'aliastofile')
    @ap.make_alias(@pp)
    @sl = Pathname.new(@tmpdir + 'symlink')
    @sl.make_symlink(@ap) # Symlink to @ap
  end

  def teardown
    @tmpdir.rmtree
  end

  def test_make_alias
    assert @ap.exist?, 'Alias not created'
  end

  def test_alias?
    assert @ap.alias?, 'Alias not recognized'
    refute @sl.alias?, 'A symlink should not be an alias'
  end

  def test_original
    assert_equal @pp, @pp.original
    assert_equal @pp, @ap.original
    assert_equal @ap, @sl.original
  end
  
end # TestAliases


class TestComments < MiniTest::Unit::TestCase

  def setup
    # Note that, if you create a file X, set a Spotlight comment for X,
    # delete X, then create another file called X, the new X will still have
    # the Spotlight comment, because the comment is also stored in .DS_Store.
    # To ensure that each test is executed in a clean state, we create files
    # in a temporary folder, which is deleted in teardown.
    @tmpdir = Pathname.tempdir
    @pp = Pathname.new(@tmpdir + 'somefile')
    @pp.write('')
    @sl = Pathname.new(@tmpdir + 'symlink')
    @sl.make_symlink(@pp) # Symlink to @pp
    @subdir = Pathname.new(@tmpdir + 'subdir')
    @subdir.mkpath
  end

  def teardown
    #@tmpdir.rmtree
  end

  def test_set_and_get_spotlight_comment
    @subdir.spotlight_comment = 'Hi there'
    assert_equal 'Hi there', @subdir.spotlight_comment
    @subdir.spotlight_comment = ''
    assert_equal '', @subdir.spotlight_comment
    @pp.spotlight_comment = 'Hi there'
    assert_equal 'Hi there', @pp.spotlight_comment
    @pp.spotlight_comment = ''
    assert_equal '', @pp.spotlight_comment
  end

  def test_spotlight_comment_on_symlink
    assert_equal '', @pp.spotlight_comment, 'The file should be created without a comment'
    assert_equal '', @sl.spotlight_comment, 'The symlink should be created without a comment' 
    @sl.spotlight_comment = 'Hi there'
    assert_equal 'Hi there', @sl.spotlight_comment, 'The symlink should have a comment'
    assert_equal '', @pp.spotlight_comment, 'The file should not have a comment'
  end

end # TestComments

class TestResourceFork < MiniTest::Unit::TestCase

  def setup
    rsrc = <<EOS
resource 'STR#' (128, "Test Resource Fork") {
  {	"KEY=value" };
};
EOS
    @fr = Pathname.tempfile
    @fr.rez(rsrc)
  end

  def teardown
    @fr.unlink if @fr.exist?
  end

  def test_read_resource_fork
    result = <<EOS
data 'STR#' (128, "Test Resource Fork") {
	$"0001 094B 4559 3D76 616C 7565"                      /* ..\xC6KEY=value */
};

EOS
    assert_equal result.force_encoding('macRoman'), @fr.derez
  end

  def test_compare_resource_forks
    res1 = @fr.derez
    res2 = @fr.derez
    assert_equal res1, res2
  end

  def test_empty_resource_fork
    t = Pathname.tempfile
    assert_equal '', t.derez
  end

  def test_hexadecimal_dump_of_resource_fork
    result = <<EOS
0000000 00 00 01 00 00 00 01 10 00 00 00 10 00 00 00 45
0000010 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
*
0000100 00 00 00 0c 00 01 09 4b 45 59 3d 76 61 6c 75 65
0000110 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
0000120 00 00 00 00 00 00 00 00 00 1c 00 32 00 00 53 54
0000130 52 23 00 00 00 0a 00 80 00 00 00 00 00 00 00 00
0000140 00 00 12 54 65 73 74 20 52 65 73 6f 75 72 63 65
0000150 20 46 6f 72 6b                                 
0000155
EOS
    assert_equal result, @fr.rez_dump
  end

end # TestResourceFork

class TestCompareFiles < MiniTest::Unit::TestCase

  def setup
    @f1 = Pathname.tempfile
    @f2 = Pathname.tempfile
    @f3 = Pathname.tempfile
  end

  def teardown
    @f1.unlink if @f1.exist?
    @f2.unlink if @f2.exist?
    @f3.unlink if @f3.exist?
  end

  def test_compare_file_content
    @f1.write('abcde')
    @f2.write('abcde')
    @f3.write('abcdf')
    assert @f1.compare(@f2), 'f1 differs from f2'
    assert @f2.compare(@f1), 'f2 differs from f1'
    refute @f1.compare(@f3), 'f1 and f3 should differ'
  end

end # TestCompareFiles


class TestWriteOptions < MiniTest::Unit::TestCase

  def setup
    @f1 = Pathname.tempfile
  end

  def teardown
    @f1.unlink if @f1.exist?
  end

  def test_write_uncompressed
    @f1.write_random('1k')
    refute @f1.compressed?, 'The file should not be compressed'
  end

  def test_write_compressed
    @f1.write_random('1k', :compressed => true)
    assert @f1.compressed?, 'The file should be compressed'
  end

#   # It does not seem possible to use HFS+ compression with a file
#   # containing a resource fork (tested on OS X 10.8). So, this test fails.
#   def test_write_compressed_with_resource_fork
#     rsrc = <<EOS
# resource 'STR#' (128, "Test Resource Fork") {
#   {  "KEY=value" };
# };
# EOS
#     @f1.write_random('1k', :rsrc => rsrc, :compressed => true)
#     result = <<EOS
# data 'STR#' (128, "Test Resource Fork") {
#   $"0001 094B 4559 3D76 616C 7565"                      /* ..\xC6KEY=value */
# };
# 
# EOS
#     assert_equal result.force_encoding('macRoman'), @f1.derez
#     assert @f1.compressed?, 'The file should be compressed'
#   end

end # TestWriteOptions
