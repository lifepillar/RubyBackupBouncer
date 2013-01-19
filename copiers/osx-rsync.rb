=begin
Copies the data using the version of rsync provided with Mac OS X:

  sudo /usr/bin/rsync -aH -E --super <source>/ <target>
  
NOTE: the version of rsync provided with Snow Leopard, Lion and 
Mountain Lion (rsync 2.6.9 protocol version 29) is somewhat buggy
and may hang. If that happens, press ctrl-c to interrupt the process.
=end

task :clone do
  begin
    target = make_volume 'rsync', :ram => true
    puts '===> [clone] OS X rsync'
    puts '-' * 70
    puts 'NOTE: OS X rsync may get stuck with some tests. If that seems'
    puts 'to be the case, press ctrl-C to interrupt the process.'
    puts '-' * 70
    copier = '/usr/bin/rsync'
    args = ['-aH']
    args << '--extended-attributes' << '--itemize-changes' << '--super'
    args << "--rsync-path=#{copier}"
    args << $source.mount_point.to_s + '/' << target.mount_point
    begin
      run_baby_run copier, args, :sudo => true, :verbose => false
    rescue => ex
      puts "rsync clone task has failed: #{ex}"
    end
  rescue Rbb::DiskImageExists
    puts 'Skipping rsync clone task (volume exists).'
  end
end

task :copy do
  target = $target + 'rsync'
  if target.exist?
    puts 'Skipping rsync copy task (folder exists).'
  else
    puts '===> [copy] OS X rsync'
    target.mkpath
    copier = '/usr/bin/rsync'
    args = ['-aH']
    args << '--extended-attributes' << '--itemize-changes' << '--super'
    args << "--rsync-path=#{copier}"
    args << $source.to_s + '/' << target
    begin
      run_baby_run copier, args, :sudo => true, :verbose => false
    rescue => ex
      puts "rsync clone task has failed: #{ex}"
    end
  end
end