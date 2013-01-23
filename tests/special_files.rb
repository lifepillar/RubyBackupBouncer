=begin
Checks whether Unix special files (fifos and devices)
are copied to the target. It also checks whether creation and
modification dates on such files are preserved.
=end

task :fill do
  topdir = $source + 'special-files'
  if topdir.exist?
    puts 'Skipping special-files (folder exists).'
  else
    puts '===> [fill] special-files'
    topdir.mkpath
    # Named pipe
    fifo = topdir + 'fifo'
    begin
      run_baby_run 'mkfifo', [fifo]
      # Character device
      run_baby_run 'mknod', [topdir+'devzero', 'c', '3', '3'], :sudo => true
      # Block device
      run_baby_run 'mknod', [topdir+'devvn0', 'b', '1', '0'], :sudo => true
      # Whiteout node?
    rescue => ex
      puts "Populating special-files has failed: #{ex}"
    end
  end
end

#############################################################################
# Tests
#############################################################################

class UnixSpecialFiles < Rbb::TestCase
  
  def setup
    set_wd 'special-files'
  end

  def test_filed_copied?
    check_files_copied    
  end

  def test_unix_named_pipes
    fifo = all_files.select { |f| f.file_type =~ /Fifo/i }
    verify_property fifo do |source,target,name|
      assert_equal source.file_type, target.file_type, name
    end
  end

  def test_creation_times_on_named_pipes
    fifo = all_files.select { |f| f.file_type =~ /Fifo/i }
    verify_property fifo do |source,target,name|
      assert_equal source.creation_time, target.creation_time, name
    end
  end
  
  def test_modification_dates_on_named_pipes
    fifo = all_files.select { |f| f.file_type =~ /Fifo/i }
    verify_property fifo do |source,target,name|
      assert_equal source.modification_time,  target.modification_time, name
    end
  end
  
  def test_unix_devices
    devices = all_files.select { |f| f.file_type =~ /Device/i }
    verify_property devices do |source,target,name|
      assert_equal source.file_type, target.file_type, name
    end
  end

  def test_creation_times_on_devices
    devices = all_files.select { |f| f.file_type =~ /Device/i }
    verify_property devices do |source,target,name|
      assert_equal source.creation_time, target.creation_time, name
    end
  end

  def test_modification_dates_on_devices
    devices = all_files.select { |f| f.file_type =~ /Device/i }
    verify_property devices do |source,target,name|
      assert_equal source.modification_time,  target.modification_time, name
    end
  end
end
