=begin
Clones a volume using GNU ddrescue.

GNU ddrescue (http://www.gnu.org/software/ddrescue/ddrescue.html) is a
data recovery tool. It copies data from one file or block device (hard
disc, cdrom, etc) to another, trying hard to rescue data in case of
read errors.

This task unmounts the source and target volumes, then runs

sudo ddrescue <source device> <target device> --force

then remounts the volumes. For convenience, this task renames the
target volume after cloning.

GNU ddrescue can be installed via MacPorts (sudo port install ddrescue)
or with Homebrew (brew install ddrescue).
=end

task :clone do
  begin
    copier = `which ddrescue 2>/dev/null`.chomp!
    if copier =~ /ddrescue/
      target = make_volume 'ddrescue', :ram => true
      puts '===> [clone] ddrescue'
      $source.unmount
      target.unmount
      begin
        run_baby_run copier, [$source.dev_node, target.dev_node, '--force'],
          :sudo => true, :verbose => false
      rescue => ex
        puts "ddrescue clone task has failed: #{ex}"
      end
      $source.mount
      target.mount
      target.rename 'ddrescue'
    else
      puts '-' * 70
      puts 'NOTE: GNU ddrescue is not installed. You may install ddrescue using'
      puts 'Homebrew (brew install ddrescue), or'
      puts 'MacPorts (sudo port install ddrescue)'
      puts '-' * 70
    end
  rescue Rbb::DiskImageExists
    puts 'Skipping ddrescue clone task (volume exists).'
  end
end
