=begin
Copies the data using the Finder (through an AppleScript script), then
synchronizes the data with Homebrew'rsync (/usr/local/bin/rsync).

These are the commands performed by this task:

  tell app "Finder" to duplicate the entire contents of <source> to <target>
  sudo chflags -R nouchg,noschg,nosappend <target>
  sudo /usr/local/bin/rsync -aNHAX --itemize-changes --super
    --protect-args --fileflags --force-change <source>/ <target>
=end

task :clone do
  begin
    target = make_volume 'Finder+rsync', :ram => true
    puts '===> [clone] Finder+rsync'
    source_path = $source.mount_point.to_s
    target_path = target.mount_point.to_s
    setsource = "set source to \"#{source_path}\" as POSIX file as alias"
    setdest   = "set dest to \"#{target_path}\" as POSIX file as alias"
    script    = 'tell application "Finder" to duplicate the entire contents ' +
                'of source to dest with replacing'
    begin
      run_baby_run 'osascript', ['-e', setsource, '-e', setdest, '-e', script],
        :sudo => true, :verbose => false, :err => '/dev/null'
    rescue => ex
      puts "Finder+rsync clone task has exited with errors: #{ex}"
    end

    # Unlocking files should not be needed, given --force-change,
    # but rsync 3.0.7 produces errors if the following is omitted.
    puts '     rsyncing...'
    begin
      run_baby_run('chflags', ['-R', 'nouchg,noschg,nosappend', target_path],
        :sudo => true, :verbose => false)
    rescue
      puts "Finder+rsync chflags has failed: #{ex}"
    end
    rsync = '/usr/local/bin/rsync'
    args = ['-aNHAX']
    args << '--hfs-compression' << '--protect-decmpfs'
    args << '--itemize-changes' << '--super'
    args << '--fileflags' << '--force-change' << '--crtimes'
    args << "--rsync-path=#{rsync}" << '--quiet'
    source_path += '/'
    args << source_path << target_path
    begin
      run_baby_run(rsync, args, :sudo => true, :verbose => false)
    rescue
      puts "Finder+rsync clone task has failed: #{ex}"
    end
  rescue Rbb::DiskImageExists
    puts 'Skipping Finder+rsync clone task (volume exists).'
  end
end

task :copy do
  target = $target + 'Finder+rsync'
  if target.exist?
    puts 'Skipping Finder+rsync copy task (folder exists).'
  else
    puts '===> [copy] Finder+rsync'
    target.mkpath
    setsource = "set source to \"#{$source}\" as POSIX file as alias"
    setdest   = "set dest to \"#{target}\" as POSIX file as alias"
    script    = 'tell application "Finder" to duplicate the entire contents ' +
                'of source to dest with replacing'
    begin
      run_baby_run 'osascript', ['-e', setsource, '-e', setdest, '-e', script], :sudo => true
    rescue => ex
      puts "Finder+rsync clone task has failed: #{ex}"
    end
  
    # Unlocking files should not be needed, given --force-change,
    # but rsync 3.0.7 produces errors if the following is omitted
    begin
      run_baby_run('chflags', ['-R', 'nouchg,noschg,nosappend', target_path],
        :sudo => true, :verbose => false)
    rescue
      puts "Finder+rsync chflags has failed: #{ex}"
    end
    rsync = '/usr/local/bin/rsync'
    args = ['-aNHAX']
    args << '--hfs-compression' << '--protect-decmpfs'
    args << '--itemize-changes' << '--super'
    args << '--fileflags' << '--force-change' << '--crtimes'
    args << "--rsync-path=#{rsync}" << '--quiet'
    source_path += '/'
    args << source_path << target_path
    begin
      run_baby_run(rsync, args, :sudo => true, :verbose => false)
    rescue
      puts "Finder+rsync clone task has failed: #{ex}"
    end
  end
end
