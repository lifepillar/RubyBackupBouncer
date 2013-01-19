=begin
Verifies whether resource forks are preserved.
=end

task :fill do
  topdir = $source + 'resource-forks'
  if topdir.exist?
    puts 'Skipping resource-forks (folder exists).'
  else
    puts '===> [fill] resource-forks'
    topdir.mkpath
    f = topdir + 'file-one-with-resource-fork'
    rsrc = <<EOS
resource 'STR#' (128, "Test Resource Fork") {
  {  "KEY=value" };
};
EOS
    f.write_random('1k', :rsrc => rsrc)
    # Apple's rsync had issues with resource forks + hardlinks
    # Let's see what happens...
    f = topdir + 'file-two-with-resource-fork'
    f.write_random('1k', :rsrc => rsrc)
    (topdir + ('hardlink-' + f.basename.to_s)).make_link(f)
  end
end

#############################################################################
# Tests
#############################################################################

class ResourceForks < Rbb::TestCase

  def setup
    set_wd 'resource-forks'
  end

  def test_files_copied?
    check_files_copied
  end
  
  def test_resource_forks
    verify_property all_files do |source,target,name|
      assert_equal source.derez, target.derez, name
      assert source.rez_dump == target.rez_dump, name
    end
  end

end # ResourceForks
