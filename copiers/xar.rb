=begin
Copies the data using xar (provided with Mac OS X):

  sudo xar -c -f <tmp> . && cd <target> && sudo xar -x -P -f <tmp>
=end

task :clone do
  begin
    target = make_volume 'xar', :ram => true
    puts '===> [clone] xar'
    copier = '/usr/bin/xar'
    # xar doesn't work with pipes yet, so we use a tmpfile
    tmpfile = `mktemp -t rbbouncer-xar.XXXX`.chomp!
    begin
      $source.mount_point.cd do
        run_baby_run copier, ['-c', '-f', tmpfile, '.'], :sudo => true, :verbose => false
      end
      target.mount_point.cd do
        run_baby_run copier, ['-x', '-P', '-f', tmpfile], :sudo => true, :verbose => false
      end
    rescue => ex
      puts "xar clone task has failed: #{ex}"
    end
    rm_f tmpfile, :verbose => false
  rescue Rbb::DiskImageExists
    puts 'Skipping xar clone task (volume exists).'
  end
end

task :copy do
  target = $target + 'xar'
  if target.exist?
    puts 'Skipping xar copy task (folder exists).'
  else
    puts '===> [copy] xar'
    target.mkpath
    copier = '/usr/bin/xar'
    # xar doesn't work with pipes yet, so we use a tmpfile
    tmpfile = `mktemp -t rbbouncer-xar.XXXX`.chomp!
    begin
      $source.cd do
        run_baby_run copier, ['-c', '-f', tmpfile, '.'], :sudo => true, :verbose => false
      end
      target.cd do
        run_baby_run copier, ['-x', '-P', '-f', tmpfile], :sudo => true, :verbose => false
      end
    rescue => ex
      puts "xar copy task has failed: #{ex}"
    end
    rm_f tmpfile, :verbose => false
  end
end
