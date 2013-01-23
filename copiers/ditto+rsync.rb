=begin
Copies the data using ditto (provided with Mac OS X), then synchronizes
the data with Homebrew's rsync (/usr/local/bin/rsync)

These are the commands performed by this task:

  sudo /usr/bin/ditto <source> <target>
  sudo chflags -R nouchg,noschg,nosappend <target>
  sudo /usr/local/bin/rsync -aNHAX --itemize-changes --super
    --protect-args --fileflags --force-change <source>/ <target>
=end

task :clone do
  begin
    target = make_volume 'ditto+rsync', :ram => true
    puts '===> [clone] ditto+rsync'
    ditto = '/usr/bin/ditto'
    ditto_args = [$source.mount_point, target.mount_point]
    rsync = '/usr/local/bin/rsync'
    rsync = '/usr/local/bin/rsync'
    rsync_args = ['-aNHAX']
    rsync_args << '--hfs-compression' << '--protect-decmpfs'
    rsync_args << '--itemize-changes' << '--super'
    rsync_args << '--fileflags' << '--force-change' << '--crtimes'
    rsync_args << "--rsync-path=#{rsync}" << '--quiet'
    rsync_args << $source.mount_point.to_s + '/' << target.mount_point
    begin
      run_baby_run ditto, ditto_args, :sudo => true, :verbose => false,
        :redirect_stderr_to_stdout => true
    rescue
      puts 'ditto has exited with errors, but rsync may fix them.'
    end
    begin
      # Unlocking files should not be needed, given --force-change,
      # but rsync 3.0.7 produces errors if the following is omitted
      run_baby_run 'chflags', ['-R', 'nouchg,noschg,nosappend', target.mount_point],
        :sudo => true, :verbose => false
    rescue
      puts 'Could not unlock files.'
    end
    begin
      run_baby_run rsync, rsync_args, :sudo => true, :verbose => false
    rescue
      puts 'rsync has exited with errors. Some files may not have been copied correctly.'
    end
  rescue Rbb::DiskImageExists
    puts 'Skipping ditto+rsync clone task (volume exists).'
  end
end

task :copy do
  target = $target + 'ditto+rsync'
  if target.exist?
    puts 'Skipping ditto+rsync copy task (folder exists).'
  else
    puts '===> [copy] ditto+rsync'
    target.mkpath
    ditto = '/usr/bin/ditto'
    ditto_args = [$source, target]
    rsync = '/usr/local/bin/rsync'
    rsync_args = ['-aNHAX']
    rsync_args << '--hfs-compression' << '--protect-decmpfs'
    rsync_args << '--itemize-changes' << '--super'
    rsync_args << '--fileflags' << '--force-change' << '--crtimes'
    rsync_args << "--rsync-path=#{rsync}" << '--quiet'
    rsync_args << $source.to_s + '/' << target
    begin
      run_baby_run ditto, ditto_args, :sudo => true, :verbose => false,
        :redirect_stderr_to_stdout => true
    rescue
      puts 'ditto has exited with errors, but rsync may fix them.'
    end
    begin
      # Unlocking files should not be needed, given --force-change,
      # but rsync 3.0.7 produces errors if the following is omitted
      run_baby_run 'chflags', ['-R', 'nouchg,noschg,nosappend', target],
        :sudo => true, :verbose => false
    rescue
      puts 'Could not unlock files.'
    end
    begin
      run_baby_run rsync, rsync_args, :sudo => true, :verbose => false
    rescue
      puts 'rsync has exited with errors. Some files may not have been copied correctly.'
    end
  end
end
