# Test case template

=begin
Here goes a description of this test case.
=end

task :fill do
  # Use $source to refer to the location to populate.
  # You should populate a subfolder inside $source.
  testfolder = $source + 'testfolder' # => Pathname
  if testfolder.exist?
    puts 'Skipping testfolder (folder exists).'
  else
    testfolder.mkpath
    # Add code here to populate testfolder. For example:
    #
    #     sh "touch #{testfolder}/foo.txt"
end

# Add your tests in the class below.

class MyTestCase < Rbb::TestCase

  # Set the working directory before running a test.
  def setup
    set_wd 'testfolder'
  end
  
  # Test methods must begin with 'test_'
  def test_check_some_property
    # Use @src and @dst to refer to the source and the target, respectively.
    assert @src.directory?, 'The source folder is not a directory'
    assert @dst.exist?, 'The destination path does not exist'
    # Check assertions for a list of files with
    # the helper method verify_property (See Rbb::TestCase).
    verify_property all_files do |source,target,name|
      assert source.size == target.size, "The size of #{name} differs"
    end
  end

end
