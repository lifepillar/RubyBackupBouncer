=begin
Verifies whether metadata is preserved when copying a
file with lots of metadata (extended attributes, resource forks, acls,
BSD flags and other file attributes), and which is possibly hidden
and/or locked. This test case does not perform any check that is not
already done by other test cases: but it does those same checks on a
file with lots of metadata, rather than on a file with only the
specific metadata being tested.
=end

task :fill do
  topdir = $source + 'rich-metadata'
  if topdir.exist?
    puts 'Skipping rich-metadata (folder exist).'
  else
    puts '===> [fill] rich-metadata'
    topdir.mkpath
    locked = [false,true]
    hidden = [false,true]
    hidden.each do |is_hidden|
      h = is_hidden ? '-and-hidden' : ''
      locked.each do |is_locked|
        l = is_locked ? '-and-locked' : ''
        f = topdir + ('file-with-lots-of-metadata' + h + l)
        rsrc = (Pathname.new(__FILE__).parent.parent + 'test/data/sample_rsrc_bigger.r').read
        f.write_random('100k', :rsrc => rsrc)
        100.times do |i|
          f.set_xattr('random.string-' + i.to_s, random_string(10*i))
        end
        system "chmod 604 #{f}"
        system "sudo SetFile -P -a ABCDEIMNSTZ #{f}"
        system "sudo SetFile -P -a V #{f}" if is_hidden
        system "chmod +a \"admin allow read,writesecurity,delete\" #{f}"
        system "chmod +a \"nobody allow read,write\" #{f}"
        system "sudo chown _www #{f}"
        system "sudo chgrp staff #{f}"
        system "sudo chflags uappnd,nodump #{f}"
        system "sudo SetFile -a L #{f}" if is_locked
      end
    end
  end
end

#############################################################################
# Tests
#############################################################################

class RichMetadata < Rbb::TestCase
  
  def setup
    set_wd 'rich-metadata'
  end

  def test_files_copied?
    check_files_copied
  end

  def test_data_content_is_preserved
    verify_property all_files do |source,target,name|
      assert source.compare(target), "The data content of #{name} is corrupted"
    end
  end
  
  def test_owner
    verify_property all_files do |source,target,name|
      assert_equal source.owner, target.owner, name
    end
  end
  
  def test_group
    verify_property all_files do |source,target,name|
      assert_equal source.group, target.group, name
    end
  end
  
  def test_permissions
    verify_property all_files do |source,target,name|
      assert_equal source.permissions, target.permissions,
    end
  end

  def test_acl
    verify_property all_files do |source,target,name|
      assert_equal source.acl, target.acl, name
    end
  end

  def test_bsd_flags
    verify_property all_files do |source,target,name|
      assert_equal source.bsd_flags, target.bsd_flags, name
    end
  end

  def test_file_attributes
    verify_property all_files do |source,target,name|
      assert_equal source.attributes, target.attributes, name
    end
  end
  
  def test_extended_attributes
    n = 0
    verify_property all_files do |source,target,name|
      source.extended_attributes.each do |x|
        n += 1
        assert source.xattr(x) == target.xattr(x), "Extended attribute #{x} is not preserved by #{name}"
      end
    end
    assert n > 0, 'Failed to retrieve extended attributes'
  end
  
  def test_resource_fork
    verify_property all_files do |source,target,name|
      assert source.derez == target.derez, name 
      assert source.rez_dump == target.rez_dump, name
    end
  end

end # RichMetadata
