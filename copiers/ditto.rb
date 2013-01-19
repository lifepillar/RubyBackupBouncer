=begin
Copies data using ditto (provided with Mac OS X):

  sudo /usr/bin/ditto <source> <target>
=end

task :clone do
  begin
    target = make_volume 'ditto', :ram => true
    puts '===> [clone] ditto'
    copier = '/usr/bin/ditto'
    args = [$source.mount_point, target.mount_point]
    begin
      run_baby_run copier, args, :sudo => true, :verbose => false
    rescue => ex
      puts "ditto clone task has failed: #{ex}"
    end
  rescue Rbb::DiskImageExists
    puts 'Skipping ditto clone task (volume exists).'
  end
end

task :copy do
  target = $target + 'ditto'
  if target.exist?
    puts 'Skipping ditto copy task (folder exists).'
  else
    puts '===> [copy] ditto'
    target.mkpath
    copier = '/usr/bin/ditto'
    args = [$source, target]
    begin
      run_baby_run copier, args, :sudo => true, :verbose => false
    rescue => ex
      puts "ditto clone task has failed: #{ex}"
    end
  end
end
