=begin
Clones a volume using dd_rescue.

dd_rescue (http://www.garloff.de/kurt/linux/ddrescue/) is modeled
after dd but optimized for copying data from possible damaged disks to
your system.

This task unmounts the source and target volumes, then runs

sudo dd_rescue <source device> <target device>

then remounts the volumes. For convenience, this task renames the
target volume after cloning.

dd_rescue can be installed via MacPorts (sudo port install dd_rescue).
=end

task :clone do
  begin
    copier = `which dd_rescue 2>/dev/null`.chomp!
    if copier =~ /dd_rescue/
      target = make_volume 'dd_rescue', :ram => true
      puts '===> [clone] dd_rescue'
      $source.unmount
      target.unmount
      begin
        run_baby_run copier, [$source.dev_node, target.dev_node], :sudo => true, :verbose => false
      rescue => ex
        puts "dd_rescue clone task has failed: #{ex}"
      end
      $source.mount
      target.mount
      target.rename('dd_rescue')
    else
      puts '-' * 70
      puts 'NOTE: dd_rescue is not installed. You may install dd_rescue using'
      puts 'MacPorts (sudo port install dd_rescue)'
      puts '-' * 70
    end
  rescue Rbb::DiskImageExists
    puts 'Skipping dd_rescue clone task (volume exists).'
  end
end
