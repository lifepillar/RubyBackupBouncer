=begin
Copies the data using tar (provided with Mac OS X):

  sudo tar -cf - -C <source> . | sudo tar -x --preserve -f -C <target>
=end

task :clone do
  begin
    target = make_volume 'tar', :ram => true
    puts '===> [clone] tar'
    copier = '/usr/bin/tar'
    cmd = "sudo echo && sudo #{copier} -cf - -C #{$source.mount_point} . | sudo #{copier} -x --preserve -f - -C #{target.mount_point}"
    puts cmd
    status = system(cmd)
    puts "tar clone task has failed: #{$?}" if status.nil? or (not status)
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
    cmd = "sudo echo && sudo #{copier} -cf - -C #{$source} . | sudo #{copier} -x --preserve -f - -C #{target}"
    puts cmd
    unless system cmd
      puts "tar clone task has failed: #{$?}"
    end
  end
end
