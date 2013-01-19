=begin
Clones a volume using dd (provided with Mac OS X).

This task unmounts the source and target volumes, then runs

sudo /bin/dd if=<source device> of=<target device>

then remounts the volumes. For convenience, this task renames the
target volume after cloning.
=end

task :clone do
  begin
    target = make_volume('dd', :ram => true) # => Volume
    puts '===> [clone] dd'
    copier = '/bin/dd'
    # Create a test volume if it doesn't exist
    # dd needs the volumes to be unmounted
    $source.unmount
    target.unmount
    begin
      run_baby_run copier, ["if=#{$source.dev_node}", "of=#{target.dev_node}"],
        :sudo => true, :verbose => false
    rescue Exception => ex
      puts "ERROR: #{copier} did fail: #{ex}"
    end
    # Remount volumes
    $source.mount
    target.mount
    target.rename('dd')
  rescue Rbb::DiskImageExists
    puts 'Skipping dd clone task (volume exists).'
  end
end
