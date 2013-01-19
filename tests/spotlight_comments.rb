=begin
Verifies whether Spotlight comments are copied to the
target. Since Spotlight comments are stored as extended attributes,
this test case should always succeed whenever extended attributes are
preserved. But, given the special nature and importance of such
attributes (which are accessible by the user through the Finder), this
test case performs an independent check.
=end

task :fill do
  topdir = $source + 'spotlight-comments'
  if topdir.exist?
    puts 'Skipping spotlight-comments (folder exists).'
  else
    puts '===> [fill] spotlight-comments'
    topdir.mkpath
    f1 = topdir + 'file-with-comment'
    f2 = topdir + 'file-with-comment-hardlinked'
    f3 = topdir + 'file-with-comment-aliased'
    f4 = topdir + 'file-with-comment-symlinked'
    d = topdir +'dir-with-comment'
    f1.write_random('1k')
    f2.write_random('1k')
    f3.write_random('1k')
    f4.write_random('1k')
    d.mkpath
    sl1 = topdir + 'symlink-broken-with-comment'
    sl1.make_symlink(Pathname.new('broken'))
    sl2 = topdir + 'symlink-with-comment'
    sl2.make_symlink(f4)
    # Surprisingly enough, OS X allows independent Spotlight comments on hardlinked files…
    hl = topdir + 'hardlink-with-comment'
    hl.make_link(f2)
    al = topdir + 'alias-with-comment'
    al.make_alias(f3)
    # Set comments
    f1.spotlight_comment = 'I am a comment on a file'
    f2.spotlight_comment = 'I am a comment on a file'
    f3.spotlight_comment = 'I am a comment on a file'
    f4.spotlight_comment = 'I am a comment on a file'
    d.spotlight_comment = 'I am a comment on a directory'
    hl.spotlight_comment = 'I am a comment on a hard link. I am different from the comment on the file!'
    sl1.spotlight_comment = 'I am a comment on a broken symbolic link!'
    sl2.spotlight_comment = 'I am a comment on a valid symbolic link!'
    al.spotlight_comment = 'I am a comment on an alias!'
    # It seems that we must wait a bit for Spotlight comments “stick”… mistery of OS X metadata :)
    sleep 5
  end
end

#############################################################################
# Tests
#############################################################################

class SpotlightComments < Rbb::TestCase
  
  def setup
    set_wd 'spotlight-comments'
  end

  def test_files_copied?
    check_files_copied
  end
  
  def test_DS_Store
    srcfile = @src + '.DS_Store'
    dstfile = @dst + '.DS_Store'
    assert srcfile.exist?, ".DS_Store does not exist in the source"
    assert dstfile.exist?, ".DS_Store does not exist in the target"
    assert srcfile.compare(dstfile), ".DS_Store files are not equal"
  end

  def test_spotlight_comments
    verify_property all_files do |source,target,name|
      comment = source.spotlight_comment
      refute (comment.nil? or comment.empty?), "Comment was not set on source file #{name}"
      assert_equal comment,  target.spotlight_comment, "Comments are not preserved for #{name}"
    end
  end

end # SpotlightComments
