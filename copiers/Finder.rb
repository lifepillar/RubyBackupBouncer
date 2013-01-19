=begin
Copies or clones using the Finder (through an AppleScript script).

Note that this Finder copy task is run with administrator privileges,
so it may not behave exactly as a drag-and-drop operation.
=end

task :clone do
  begin
    target = make_volume 'Finder', :ram => true
    puts '===> [clone] Finder'
    setsource = "set source to \"#{$source.mount_point}\" as POSIX file as alias"
    setdest   = "set dest to \"#{target.mount_point}\" as POSIX file as alias"
    script    = 'tell application "Finder" to duplicate the entire contents ' +
                'of source to dest with replacing'
    begin
      run_baby_run 'osascript', ['-e', setsource, '-e', setdest, '-e', script],
      :sudo => true, :verbose => false
    rescue => ex
      puts "Finder clone task has failed: #{ex}"
    end
  rescue Rbb::DiskImageExists
    puts 'Skipping Finder clone task (volume exists).'
  end
end

task :copy do
  target = $target + 'Finder'
  if target.exist?
    puts 'SKipping Finder copy task (folder exists).'
  else
    puts '===> [copy] Finder'
    target.mkpath
    setsource = "set source to \"#{$source}\" as POSIX file as alias"
    setdest   = "set dest to \"#{target}\" as POSIX file as alias"
    script    = 'tell application "Finder" to duplicate the entire contents ' +
                'of source to dest with replacing'
    begin
      run_baby_run 'osascript', ['-e', setsource, '-e', setdest, '-e', script],
        :sudo => true, :verbose => false
    rescue => ex
      puts "Finder copy task has failed: #{ex}"
    end
  end
end
