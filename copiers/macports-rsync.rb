=begin
Copies the data using MacPorts's rsync:

  sudo /opt/local/bin/rsync -aNHAX --itemize-changes --super
    --protect-args --fileflags --force-change <source>/ <target>

You must install rsync from MacPorts with 'sudo port install rsync'.
=end

task :clone do
  begin
    target = make_volume 'macports-rsync', :ram => true
    puts '===> [clone] MacPorts rsync'
    copier = '/opt/local/bin/rsync'
    args = ['-aNHAX']
    args << '--hfs-compression' << '--protect-decmpfs'
    args << '--itemize-changes' << '--super'
    args << '--fileflags' << '--force-change' << '--crtimes'
    args << "--rsync-path=#{copier}" << '--quiet'
    args << $source.mount_point.to_s + '/' << target.mount_point
    begin
      run_baby_run copier, args, :sudo => true, :verbose => false,
        :redirect_stderr_to_stdout => true
    rescue => ex
      puts "macports-rsync has exited with errors. Some files may not have been copied."
    end
  rescue Rbb::DiskImageExists
    puts 'Skipping macports-rsync clone task (volume exists).'
  end
end

task :copy do
  target = $target + 'macports-rsync'
  if target.exist?
    puts 'Skipping macports-rsync copy task (folder exists).'
  else
    puts '===> [copy] MacPorts rsync'
    target.mkpath
    copier = '/opt/local/bin/rsync'
    args = ['-aNHAX']
    args << '--hfs-compression' << '--protect-decmpfs'
    args << '--itemize-changes' << '--super'
    args << '--fileflags' << '--force-change' << '--crtimes'
    args << "--rsync-path=#{copier}" << '--quiet'
    args << $source.to_s + '/' << target
    begin
      run_baby_run copier, args, :sudo => true, :verbose => false,
        :redirect_stderr_to_stdout => true
    rescue => ex
      puts "macports-rsync has exited with errors. Some files may not have been copied."
    end
  end
end
