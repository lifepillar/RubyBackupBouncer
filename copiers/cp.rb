=begin
Copies the data using cp -Rp.
=end

task :clone do
  begin
    target = make_volume 'cp', :ram => true
    puts '===> [clone] cp'
    copier = '/bin/cp'
    args = ['-Rpn']
    args += Pathname.glob($source.mount_point+'*')
    args << target.mount_point
    begin
      run_baby_run copier, args, :sudo => true, :verbose => false
    rescue => ex
      puts "#{copier} has failed: #{ex}"
    end
  rescue Rbb::DiskImageExists
    puts 'Skipping cp clone task (volume exists).'
  end
end

task :copy do
  target = $target + 'cp'
  if target.exist?
    puts 'Skipping cp copy task (folder exists),'
  else
    puts '===> [copy] cp'
    copier = '/bin/cp'
    args = ['-Rp', $source, target]
    begin
      run_baby_run copier, args, :sudo => true, :verbose => false
    rescue => ex
      puts "#{copier} has failed: #{ex}"
    end
  end
end
