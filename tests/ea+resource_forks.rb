=begin
Checks whether files with both extended attributes and
resource forks are copied correctly.
=end

task :fill do
  topdir = $source + 'ea+rforks'
  if topdir.exist?
    puts 'Skipping ea-rforks (folder exists).'
  else
    puts '===> [fill] ea+rforks'
    topdir.mkpath
    f = topdir + 'file-with-xattr-and-resource-fork'
    rsrc = <<EOS
resource 'STR#' (128, "Test Resource Fork") {
  {  "KEY=value" };
};
EOS
    f.write_random('5k', :rsrc => rsrc)
    f.set_xattr('some.random-string', random_string(3000))
  end
end

#############################################################################
# Tests
#############################################################################

class ExtendedAttributesPlusResourceForks < Rbb::TestCase

  def setup
    set_wd 'ea+rforks'
  end

  def test_were_files_copied?
    check_files_copied
  end
  
  def test_extended_attributes
    verify_property all_files do |source,target,name|
      source.extended_attributes.each do |x|
        assert_equal source.xattr(x), target.xattr(x), name
      end
    end
  end
  
  def test_resource_fork
    verify_property all_files do |source,target,name|
        assert_equal source.derez, target.derez, name
        assert_equal source.rez_dump, target.rez_dump, name
    end
  end

end # ExtendedAttributesPlusResourceForks
