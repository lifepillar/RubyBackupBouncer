=begin
Verifies whether aliases are copied correctly.
=end

task :fill do
  topdir = $source + 'aliases'
  if topdir.exist?
    puts 'Skipping aliases (folder exists).'
  else
    puts '===> [fill] aliases'
    topdir.mkpath
    f = topdir + 'file-aliased'
    d = topdir + 'dir-aliased'
    f.write_random('1k')
    d.mkpath
    # Create aliases
    (topdir + 'alias-to-file').make_alias(f)
    (topdir + 'alias-to-dir').make_alias(d)
  end
end

#############################################################################
# Tests
#############################################################################

class Aliases < Rbb::TestCase

  def setup
    set_wd 'aliases'
  end
  
  def test_were_files_copied?
    check_files_copied
  end
   
  def test_alias_metadata
    verify_property all_aliases do |source,target,name|
      source.extended_attributes.each do |x|
        assert source.xattr(x) == target.xattr(x),
          "Extended attribute #{x} is not preserved for #{name}"
      end
    end
  end

  def test_alias_resource_fork
    verify_property all_aliases do |source,target,name|
      rsrc = source.derez
      assert_instance_of String, rsrc
      refute rsrc.empty?, "#{name} has an empty resource fork"
      assert rsrc == target.derez, name
    end
  end

  def test_copied_alias_points_to_copied_original_item
    verify_property all_aliases do |source,target,name|
      a = source.original
      b = target.original
      refute_nil a, "#{source} is broken"
      assert_equal a.relative_path_from(source), b.relative_path_from(target)
    end
  end

end # Aliases
