=begin

Copies or clones using Unison (http://www.cis.upenn.edu/~bcpierce/unison/).

Unison can be installed using Homebrew with the command:

  brew install unison

or using MacPorts with the command:

  sudo port install unison

=end

task :clone do
  begin
    copier = `which unison 2>/dev/null`.chomp!
    if copier =~ /unison/
      target = make_volume 'unison', :ram => true
      puts '===> [clone] unison'
      # Remount in read-write mode: Unison does not like if a volume is read-only
      rw = $source.writable?
      $source.remount unless rw
      args = []
      args << '-force' << 'newer' << '-group' << '-ignorearchives' << '-owner'
      args << '-perms' << '-1' << '-times' << '-silent' << '-terse'
      args << '-log' << '-logfile' << DIR_TMP + 'unison.log'
      args << $source.mount_point << target.mount_point
      begin
        run_baby_run copier, args, :sudo => true, :verbose => false
      rescue => ex
        puts "unison clone task has failed: #{ex}"
      end
      $source.remount(:force_readonly => true) unless rw
    else
      puts '-' * 70
      puts 'NOTE: unison is not installed. You may install unison using'
      puts 'MacPorts (sudo port install unison) or Homebrew (brew install unison)'
      puts '-' * 70
    end
  rescue Rbb::DiskImageExists
    puts 'Skipping unison clone task (volume exists).'
  end
end

task :copy do
  copier = `which unison 2>/dev/null`.chomp!
  if copier =~ /unison/
    target = $target + 'unison'
    if target.exist?
      puts 'Skipping unison copy task (folder exists).'
    else
      puts '===> [copy] unison'
      target.mkpath
      args = []
      args << '-force' << 'newer' << '-group' << '-ignorearchives' << '-owner'
      args << '-perms' << '-1' << '-times' << '-silent' << '-terse'
      args << '-log' << '-logfile' << DIR_TMP + 'unison.log'
      args << $source << target
      begin
        run_baby_run copier, args, :sudo => true, :verbose => false
      rescue => ex
        puts "unison clone task has failed: #{ex}"
      end
    end
  else
    puts '-' * 70
    puts 'NOTE: unison is not installed. You may install unison using'
    puts 'MacPorts (sudo port install unison) or Homebrew (brew install unison)'
    puts '-' * 70
  end
end