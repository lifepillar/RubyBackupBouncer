# Copy task template

=begin
Here goes a description of MYCOPIER.
=end

task :clone do
  begin
    target = make_volume('MYCOPIER', :ram => true) # => Volume
    # Add the code to clone source into target.
    # Use $source to refer to the source volume. For example:
    #
    #  begin
    #    run_baby_run 'MYCOPIER', $source.mount_point, target.mount_point
    #  rescue => ex
    #    puts "MYCOPIER has failed: #{ex}"
    #  end
  rescue Rbb::DiskImageExists
    puts 'Skipping MYCOPIER clone task (volume exists).'
  end
end

task :copy do
  # Use $target to refer to the destination path.
  # Files should be copied into a subfolder of $target.
  target = $target + 'MYCOPIER' # => Pathname
  if target.exist?
    puts 'Skipping MYCOPIER copy task (folder exists).'
  else
    # Add the code to copy the content of source into target.
    # Use $source to refer to the source pathname. For example:
    #
    #  begin
    #    run_baby_run 'MYCOPIER', $source, target
    #  rescue => ex
    #    puts "MYCOPIER has failed: #{ex}"
    #  end
  end
end
