module Rbb
  class TestCase < MiniTest::Unit::TestCase

    # Verifies that all files in the source have been copied to the target.
    def check_files_copied
      count = 0
      all_files.each do |source|
        count += 1
        target = @dst + source.relative_path_from(@src)
        assert (target.exist? or target.symlink?), "#{source} not copied"
      end
      assert count > 0, 'No files copied'
    end

    # Scans a list of files in the source, retrieves the corresponding copy in the target,
    # and iteratively yields (source file, target copy, file name) to the block.
    def verify_property source_list, &block
      count = 0
      source_list.each do |source|
        target = @dst + source.relative_path_from(@src)
        if target.exist?
          count += 1
          yield source, target, source.basename.to_s
        end
      end
      assert count > 0, 'There was no file to test'
    end

    def all_files
      Pathname.glob(@src + '**' + '**')
    end

    def all_directories
       Pathname.glob(@src + '**' + '**').select { |f| f.directory? }
    end

    def all_symlinks
      Pathname.glob(@src + '**' + '**').select { |f| f.symlink? }
    end

    def all_aliases
      Pathname.glob(@src + '**' + '**').select { |f| f.alias? }      
    end

    protected
    
    def set_wd path
      @src = $source + path
      @dst = $target + path
    end

  end # TestCase
end # module Rbb
