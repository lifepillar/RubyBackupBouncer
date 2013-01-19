=begin
These are the original Backup Bouncer tests by Nathaniel Gray
(http://www.n8gray.org/code/backup-bouncer/), with additional
modifications by Mike Bombich
(http://www.bombich.com/groups/ccc/wiki/7ba51/), with only very minor
changes by myself.

Note that some tests are not properly designed and may give different
results from corresponding test cases in RBB. For example, the legacy
test for resource forks on hardlinked files fails whenever hardlinks
are not preserved (so, it does not really test whether the resource
fork is preserved); the comparison of creation dates for HFS+
compressed files or for files/directories with extended attributes is
not valid and often in conflict with what the '50-creation-date' test
reports (which is correct). The legacy tests are provided for
reference, but they should be considered superseded by RBB test cases.
=end

LEGACYDIR = File.dirname(__FILE__) + '/legacy/'
LEGACYTESTRUNNER = File.dirname(__FILE__) + '/legacy/util/test-runner'

if !File.exist?(LEGACYTESTRUNNER)
  abort 'testrunner not found'
end

def legacypopulate(testname)
  thepath = File.join($source.to_s, testname)
  if File.exist?(thepath)
    puts "Skipping #{testname} (folder exists)."
  else
    puts "===> [legacy] #{testname}"
    verbose(false) do
      mkdir_p thepath
      sh(LEGACYTESTRUNNER + ' ' + File.join(LEGACYDIR, testname + '.test') + ' create ' + thepath)
    end
  end
end

task :fill do
  legacypopulate '00-basic-permissions'
  legacypopulate '05-timestamps'
  legacypopulate '10-symlinks'
  legacypopulate '15-symlink-ownership'
  legacypopulate '20-hardlinks'
#  legacypopulate '25-aliases'
  legacypopulate '30-resource-forks'
  legacypopulate '40-finder-flags'
  legacypopulate '45-finder-locks'
  legacypopulate '50-creation-date'
  legacypopulate '60-bsd-flags'
  legacypopulate '70-extended-attrs'
  legacypopulate '75-hfs-compression'
  legacypopulate '76-hfs-compression_large'
  legacypopulate '80-access-control-lists'
  legacypopulate '90-fifo'
  legacypopulate '95-devices'
  legacypopulate '99-combo-tests'
end

#############################################################################
# Tests
#############################################################################

def legacytest(testname)
  system(LEGACYTESTRUNNER + ' ' + File.join(LEGACYDIR, testname + '.test') \
    + ' verify ' + File.join($source.to_s, testname) + " '" \
    + File.join($target.to_s + "'", testname))
end

class LegacyTests < MiniTest::Unit::TestCase

  def test_basic_permissions
    assert legacytest('00-basic-permissions'),
    'Basic permissions are not preserved.'
  end

  def test_timestamps
    assert legacytest('05-timestamps'),
    'Timestamps are not preserved.'
  end

  def test_symlinks
    assert legacytest('10-symlinks'),
    'Symlinks are not preserved.'
  end
  
  def test_symlink_ownership
    assert legacytest('15-symlink-ownership'),
    'Symlink ownership is not preserved.'
  end
  
  def test_hardlinks
    assert legacytest('20-hardlinks'),
    'Hard links are not preserved.'
  end
  
  def test_resource_forks
    assert legacytest('30-resource-forks'),
    'Resource forks are not preserved under all circumstances.'
  end  

  def test_finder_flags
    assert legacytest('40-finder-flags'),
    'Finder flags are not preserved.'
  end
  
  def test_finder_locks
    assert legacytest('45-finder-locks'),
    'Finder locks are not preserved.'
  end
  
  def test_creation_date
    assert legacytest('50-creation-date'),
    'Creation date is not preserved.'
  end
  
  def test_bsd_flags
    assert legacytest('60-bsd-flags'),
    'BSD flags are not preserved.'
  end
  
  def test_extended_attrs
    assert legacytest('70-extended-attrs'),
    'Extended attributes are not preserved under all circumstances.'
  end
  
  def test_hfs_compression
    assert legacytest('75-hfs-compression'),
    'HFS compression is not preserved.'
    assert legacytest('76-hfs-compression_large'),
    'HFS compression (large) is not preserved'
  end

  def test_acl
    assert legacytest('80-access-control-lists'),
    'ACLs are not preserved under all circumstances.'
  end
  
  def test_fifo
    assert legacytest('90-fifo'),
    'FIFO are not preserved.'
  end
  
  def test_devices
    assert legacytest('95-devices'),
    'Devices are not preserved.'
  end

  def test_combo
    assert legacytest('99-combo-tests'),
    'The combo test has failed.'
  end
  
end # Legacy tests
