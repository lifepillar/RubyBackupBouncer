=begin
Verifies whether extended attributes (EA) are preserved on
files, directories, symlinks, hardlinks and aliases, even when files
are locked and/or hidden.
=end

task :fill do
  topdir = $source + 'extended-attributes'
  if topdir.exist?
    puts 'Skipping extended-attributes (folder exists).'
  else
    puts '===> [fill] extended-attributes'
    topdir.mkpath
    bsdflags = ['none', 'uchg', 'hidden'] # uchg = Finder locked, hidden = Finder invisible
    bsdflags.each do |flag|
      f = topdir + ('file-with-ea-and-bsd-flag-' + flag)
      d = topdir + ('dir-with-ea-and-bsd-flag-' + flag)
      sf = topdir + ('symlink-to-file-with-' + flag)
      sd = topdir + ('symlink-to-dir-with-' + flag)
      af = topdir + ('alias-to-file-with-' + flag)
      ad = topdir + ('alias-to-dir-with-' + flag)
      f.write_random('1k')
      d.mkpath
      sf.make_symlink(f)
      sd.make_symlink(sd)
      af.make_alias(f)
      ad.make_alias(d)
      # Add extended attributes
      f.set_xattr('whats.mind', 'doesnt matter')
      f.set_xattr('whats.matter', 'never mind')
      d.set_xattr('mamma.mia', 'How about a nice pizza pie?')
      sf.set_xattr('good.grief', 'yes, you can put these on symlinks too')
      sd.set_xattr('wasitacatisaw', 'yes, you can put these on symlinks too')
      af.set_xattr('alias.attr', 'yes, you can put these on aliases too')
      ad.set_xattr('alias.attr', 'yes, you can put these on aliases too')
      if !flag.eql?('none') # Set flag
        system "sudo chflags #{flag} #{f}"
        system "sudo chflags #{flag} #{d}"
      end
    end
    # Create files with big (nearly 4kb) extended attributes
    f = topdir + 'file-with-big-ea'
    d = topdir + 'dir-with-big-ea'
    sf = topdir + 'symlink-to-file-with-big-ea'
    sd = topdir + 'symlink-to-dir-with-big-ea'
    af = topdir + 'alias-to-file-with-big-ea'
    ad = topdir + 'alias-to-dir-with-big-ea'
    f.write_random('1k')
    d.mkpath
    sf.make_symlink(f)
    sd.make_symlink(d)
    af.make_alias(f)
    ad.make_alias(d)
    f.set_xattr('key.one', random_string(3800))
    f.set_xattr('key.two', random_string(3800))
    d.set_xattr('key.dir', random_string(3800))
    sf.set_xattr('key.link', random_string(3800))
    sd.set_xattr('wasitacatisaw', 'yes, you can put these on symlinks too')
    af.set_xattr('key.alias.file', random_string(3800))
    ad.set_xattr('key.alias.dir', random_string(3800))
  end  
end

#############################################################################
# Tests
#############################################################################

class ExtendedAttributes < Rbb::TestCase
  
  def setup
    set_wd 'extended-attributes'
  end

  def test_were_files_copied?
    check_files_copied
  end
  
  def test_extended_attributes_list
    verify_property all_files do |source,target,name|
      source_xattrs = source.extended_attributes
      assert source_xattrs.size > 0, "The source file #{name} has no extended attributes"
      assert_equal source_xattrs, target.extended_attributes, name
    end
  end

  def test_extended_attributes_on_files_and_aliases
    files = all_files.select { |f| f.file? and (not f.symlink?) }
    verify_property files do |source,target,name|
      source.extended_attributes.each do |x|
        assert source.xattr(x) == target.xattr(x),
          "Extended attribute #{x} is not preserved by #{name}"
      end
    end
  end

  def test_extended_attributes_on_directories
    dirs = all_files.select { |f| f.directory? and (not f.symlink?) }
    verify_property dirs do |source,target,name|
      source.extended_attributes.each do |x|
      assert source.xattr(x) == target.xattr(x),
        "Extended attribute #{x} is not preserved by #{name}"
      end
    end
  end
  
  def test_extended_attributes_on_symlinks
    verify_property all_symlinks do |source,target,name|
      source.extended_attributes.each do |x|
        assert source.xattr(x) == target.xattr(x),
          "Extended attribute #{x} is not preserved by #{name}"
        # The extended attributes on the symlink have been set so that
        # they are different from the extended attributes of the linked file.
        # Let us check that.
        refute_equal target.extended_attributes, target.original.extended_attributes,
          "The xattrs on the symlink should not be the same as those on the linked file."
      end
    end
  end

end # ExtendedAttributes
