# Ruby Backup Bouncer (RBB)

>Gleefully brought to you by [Lifepillar](http://lifepillar.com)!

## What is it?

RBB was born as a porting in Ruby of the famous Backup
Bouncer test suite for Mac OS X originally written by
Nathaniel Gray and available at
<http://www.n8gray.org/code/backup-bouncer/>.
That is, RBB is a suite of tests to evaluate how good (or
bad) various backup tools are in backing up _OS X metadata_.
It comes with pre-defined backup tests for various programs
(cp, ditto, rsync, asr, the Finder, etc…), but it can be
used to test any backup software.

RBB improves over the original Backup Bouncer by providing
more copy tasks, more test cases, more output formats,
and a more convenient way to manage different tasks
from the command-line through Rake. RBB includes the
original tests by N. Gray (with modifications by
Carbon Copy Cloner's author) as a legacy test case.

## Requirements

- XCode Developer Tools (for `SetFile` and `GetFileInfo`);
- Ruby 1.8.7 or later;
- a few additional Ruby gems: bundler (optional, to make it easier to install all the needed dependencies), rake, rdoc (optional, for generating the documentation),
  minitest, plist, ansi and turn;
- familiarity with the command-line.

RBB has been tested on Mac OS X 10.6 (Snow Leopard),
10.7 (Lion) and 10.8 (Mountain Lion).
It should work under previous versions of the OS,
but that is untested.

## Installation

The best way to install the required gems is to use
[Bundler](http://gembundler.com). To install bundler:
  
    gem install bundler

Depending on your system configuration, you may need to run
the above commands with `sudo`. That is certainly the case
if you are using the version of Ruby that comes with OS X.
If you use [rbenv](http://rbenv.org) or
[rvm](https://rvm.io), then you should probably run the
above command without `sudo`.

All the dependencies can be installed inside the `vendor` 
subdirectory with

    bundle install

This command must always be run _without_ `sudo`!

## Getting Started

Tasks are run using `rake`.

**You should never run `rake` with `sudo`**. This is
important for tests to behave properly. When administrator
privileges are needed to carry out a task, RBB
asks you to type an administrator password.

The simplest way to run the test suite is by executing

    rake autoclone

or

    rake autocopy

Both tasks will create and mount a disk image called `srcvol`, fill it with test data, copy the data with every enabled copier and verify the copy by running all
the enabled test cases.

The difference between the two tasks is that the first
will create a new target volume for each copy task, while
the second will copy the data into subfolders of `./tmp`. Note that some copy tasks (for example, `asr` or `dd`) can only clone the source volume into a new volume and cannot
copy the source data into a folder, so they will be silently ignored by `rake autocopy`.

To remove the generated files, use

    rake clean
  
The above command will leave the source volume (`srcvol`)
intact. To clean really everything you may run the more aggressive

    rake clobber

For a list of the available tasks, use `rake -T`. A detailed
description of a task can be obtained with
`rake -D <task name>`.

## Other Examples

- Disable all copiers, enable `ditto`, create a volume, fill it with data, clone it and verify the copy made by `ditto`:

        rake dis[copiers]
        rake en[ditto]
        rake mkvol
        rake fill
        rake clone
        rake verify dst=/Volumes/ditto
