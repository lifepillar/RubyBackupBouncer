=begin
Verifies whether symbolic links are preserved.
=end

task :fill do
  topdir = $source + 'symlinks'
  if topdir.exist?
    puts 'Skipping symlinks (folder exists).'
  else
    puts '===> [fill] symlinks'
    topdir.mkpath
    f = topdir + 'file-symlinked'
    d = topdir + 'dir-symlinked'
    f.write_random('1k')
    d.mkpath
    # Create symlinks
    lf = topdir + 'symlink-to-file'
    lf.make_symlink(f)
    ld = topdir + 'symlink-to-dir'
    ld.make_symlink(d)
    lb = topdir + 'symlink-broken'
    lb.make_symlink(Pathname.new('bogus_file'))
    ll = topdir + 'symlink-to-symlink'
    ll.make_symlink(lf)
    lbl = topdir + 'symlink-to-broken-symlink'
    lbl.make_symlink(lb)
  end
end

#############################################################################
# Tests
#############################################################################

class Symlinks < Rbb::TestCase
  
  def setup
    set_wd 'symlinks'
  end

  def test_symlinks_copied?
    check_files_copied
  end
  
  def test_readlink
    verify_property all_symlinks do |source,target,name|
      a = run_baby_run 'readlink', [source], :sudo => (not source.owned?)
      b = run_baby_run 'readlink', [target], :sudo => (not target.owned?)
      assert_equal a, b, "The symlink #{name} does not point to the correct file"
    end
  end

  def test_original_item_is_the_same_for_both_source_and_target
    verify_property all_symlinks do |source,target,name|
      assert_equal source.original, target.original
    end
  end
  
  def test_symlinks_size
    verify_property all_symlinks do |source,target,name|
      assert_equal source.lsize, target.lsize, name
      assert_equal source.blocks, target.blocks, name
    end
  end

end # Symlinks
