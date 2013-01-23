=begin
Copies the data using tar (provided with Mac OS X):

  sudo tar -cf - -C <source> . -| sudo tar -x --preserve -f -C <target>
=end

task :clone do
  begin
    target = make_volume 'tar', :ram => true
    puts '===> [clone] tar'
    copier = '/usr/bin/tar'
    cmd = "sudo true && sudo #{copier} -cf - -C #{$source.mount_point} . 2>/dev/null | sudo #{copier} -x --preserve -f - -C #{target.mount_point} 2>/dev/null"
    status = system(cmd)
    if status.nil? or (not status)
      puts "tar clone task has exited with errors. Some files may not have been copied."
    end
  rescue Rbb::DiskImageExists
    puts 'Skipping tar clone task (volume exists).'
  end
end

task :copy do
  target = $target + 'tar'
  if target.exist?
    puts 'Skipping tar copy task (folder exists).'
  else
    puts '===> [copy] tar'
    target.mkpath
    copier = '/usr/bin/tar'
    cmd = "sudo true && sudo #{copier} -cf - -C #{$source} . 2>/dev/null | sudo #{copier} -x --preserve -f - -C #{target} 2>/dev/null"
    status = system(cmd)
    if status.nil? or (not status)
      puts "tar clone task has exited with errors. Some files may not have been copied."
    end
  end
end
