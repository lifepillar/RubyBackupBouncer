=begin
Copies the data using the version of rsync provided with Mac OS X:

  sudo /usr/bin/rsync -aH -E --super <source>/ <target>
  
NOTE: the version of rsync provided with Snow Leopard, Lion and 
Mountain Lion (rsync 2.6.9 protocol version 29) is somewhat buggy
and may hang. If that happens, press ctrl-c to interrupt the process.
=end

task :clone do
  begin
    target = make_volume 'osx-rsync', :ram => true
    puts '===> [clone] OS X rsync'
    puts '-' * 70
    puts 'NOTE: OS X rsync may freeze when the special_files test is enabled.'
    puts 'To interrupt the process, press ctrl-C a couple of times.'
    puts '-' * 70
    copier = '/usr/bin/rsync'
    args = ['-aH']
    args << '--extended-attributes' << '--itemize-changes' << '--super'
    args << "--rsync-path=#{copier}"
    args << $source.mount_point.to_s + '/' << target.mount_point
    begin
      run_baby_run copier, args, :sudo => true, :verbose => false,
        :redirect_stderr_to_stdout => true
    rescue
      puts "rsync clone task has exited with errors. Some files may not have been copied."
    end
  rescue Rbb::DiskImageExists
    puts 'Skipping rsync clone task (volume exists).'
  end
end

task :copy do
  target = $target + 'osx-rsync'
  if target.exist?
    puts 'Skipping rsync copy task (folder exists).'
  else
    puts '===> [copy] OS X rsync'
    puts '-' * 70
    puts 'NOTE: OS X rsync may freeze when the special_files test is enabled.'
    puts 'To interrupt the process, press ctrl-C a couple of times.'
    puts '-' * 70
    target.mkpath
    copier = '/usr/bin/rsync'
    args = ['-aH']
    args << '--extended-attributes' << '--itemize-changes' << '--super'
    args << "--rsync-path=#{copier}"
    args << $source.to_s + '/' << target
    begin
      run_baby_run copier, args, :sudo => true, :verbose => false,
        :redirect_stderr_to_stdout => true
    rescue
      puts "rsync copy task has exited with errors. Some files may not have been copied."
    end
  end
end
