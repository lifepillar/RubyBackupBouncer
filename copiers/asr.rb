=begin
Clones a volume using Apple asr in block copy mode (with --erase).

This task performs the same job as Disk Utility's Restore function
with the option "Erase Destination and replace its contents with the
contents of Source" enabled. For convenience, it renames the target
volume after cloning.
=end

task :clone do
  begin
    target = make_volume 'asr', :ram => true
    puts '===> [clone] asr'
    copier = '/usr/sbin/asr'
    options = ['restore', '--source', $source.dev_node, '--target', target.dev_node]
    options << '--erase' << '--noprompt'
    begin
      run_baby_run copier, options, :sudo => true, :verbose => false
      target.rename 'asr'
    rescue => ex
      puts "asr clone task has failed: #{ex}"
    end
  rescue Rbb::DiskImageExists
    puts 'Skipping asr clone task (volume exists).'
  end
end
