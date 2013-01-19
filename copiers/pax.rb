=begin
Copies the data using pax (provided with Mac OS X):

  cd <source> && sudo pax -rw -p e . <target>
=end

task :clone do
  begin
    target = make_volume 'pax', :ram => true
    puts '===> [clone] pax'
    copier = '/bin/pax'
    args = ['-rw', '-p', 'e', '.', target.mount_point]
    $source.mount_point.cd do
      run_baby_run copier, args, :sudo => true, :verbose => false
    end
  rescue Rbb::DiskImageExists
    puts 'Skipping pax clone task (volume exists).'
  end
end

task :copy do
  target = $target + 'pax'
  if target.exist?
    puts 'SKipping pax copy task (folder exists).'
  else
    puts '===> [copy] pax'
    target.mkpath
    copier = '/bin/pax'
    args = ['-rw', '-p', 'e', '.', target]
    $source.cd do
      run_baby_run copier, args, :sudo => true, :verbose => false
    end
  end
end
