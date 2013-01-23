=begin
Copies the data using Homebrew's rsync:

You must install rsync from Homebrew with 'brew install rsync'.
=end

task :clone do
  begin
    target = make_volume 'homebrew-rsync', :ram => true
    puts '===> [clone] Homebrew rsync'
    copier = '/usr/local/bin/rsync'
    args = ['-aNHAX']
    args << '--hfs-compression' << '--protect-decmpfs'
    args << '--itemize-changes' << '--super'
    args << '--fileflags' << '--force-change' << '--crtimes'
    args << "--rsync-path=#{copier}" << '--quiet'
    args << $source.mount_point.to_s + '/' << target.mount_point
    begin
      run_baby_run copier, args, :sudo => true, :verbose => false,
        :redirect_stderr_to_stdout => true
    rescue
      puts "homebrew-rsync has exited with errors. Some files may not have been copied."
    end
  rescue Rbb::DiskImageExists
    puts 'Skipping homebrew-rsync clone task (volume exists).'
  end
end

task :copy do
  target = $target + 'homebrew-rsync'
  if target.exist?
    puts 'Skipping homebrew-rsync copy task (folder exists).'
  else
    puts '===> [copy] Homebrew rsync'
    target.mkpath
    copier = '/usr/local/bin/rsync'
    args = ['-aNHAX']
    args << '--hfs-compression' << '--protect-decmpfs'
    args << '--itemize-changes' << '--super'
    args << '--fileflags' << '--force-change' << '--crtimes'
    args << "--rsync-path=#{copier}" << '--quiet'
    args << $source.to_s + '/' << target
    begin
      run_baby_run copier, args, :sudo => true, :verbose => false,
        :redirect_stderr_to_stdout => true
    rescue
      puts "homebrew-rsync has exited with errors. Some files may not have been copied."
    end
  end
end
