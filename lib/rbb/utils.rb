# -*- coding: utf-8 -*-
require 'shellwords'

module Rbb
  module Utils
  
  module_function

    # Prints a message if in debug mode.
    def debug msg
      return unless $DEBUG
      puts 'DEBUG:  ' + msg.to_s
    end

    # Prints a notice if in verbose mode.
    def blah notice
      return unless $VERBOSE
      puts notice.to_s
    end

    # Executes a command. Returns the output of the command.
    # Raises a runtime error if the command does not exit successfully.
    #
    # [command] A String or Pathname object
    # [arguments] An optional Array of arguments
    # [options] An optional Hash of... options (optional options, oh dear!)
    #
    # Options: dry, err, out, redirect_stderr_to_stdout, sudo, verbose
    def run_baby_run command, arguments = [], options = {}
      opts = {
        :dry => false,
        :redirect_stderr_to_stdout => false,
        :sudo => false,
        :verbose => false
      }.merge!(options)
      cmd = opts[:sudo] ? 'sudo ' : ''
      cmd << String.new(command.to_s)
      raise "Not an array" unless arguments.is_a?(Array)
      args = arguments.map { |arg| arg.to_s }
      cmd << ' '     + args.shelljoin
      cmd << ' >'    + Shellwords.shellescape(opts[:out]) if opts.has_key?(:out)
      cmd << ' 2>'   + Shellwords.shellescape(opts[:err]) if opts.has_key?(:err)
      cmd << ' 2>&1' if opts[:redirect_stderr_to_stdout]
      puts cmd if opts[:verbose]
      return cmd if opts[:dry]
      output = %x|#{cmd}| # Run baby run!
      unless $?.success?
        raise RuntimeError, output
      end
      return output
    end

    # Executes +diskutil+ with the given arguments.
    # Returns the output of +diskutil+.
    def diskutil *args
      run_baby_run 'diskutil', args
    end

    # Executes +hdiutil+ with the given arguments.
    # Returns the output of +hdiutil+.
    def hdiutil *args
      run_baby_run 'hdiutil', args
    end

    # Returns the size, in bytes, of an expression of the type
    # ??|??b|??k|??m|??g (b specifies the number of sectors, not bytes, as in
    # +hdiutil+).
    def size_to_bytes expr
      return expr if expr.is_a?(Fixnum)
      data = expr.match(/(\d+)([bkmg]?)/i)
      if data and data.size == 3
        if data[2].eql?("") # no unit, assume bytes
          return data[1].to_i
        end
        units = { 'b' => 512, 'k' => 2**10, 'm' => 2**20, 'g' => 2**30 }
        return data[1].to_i * units[data[2].downcase]
      end
      return 0
    end

    # A very trivial method to generate a random string of a given length.
    def random_string length
    	chars = ('a'..'z').to_a + ('A'..'Z').to_a + ("0".."9").to_a
      n = chars.size
    	s = ''
    	length.times { s << chars[rand(n)] }
    	return s
    end

  end # module Utils
end # module Rbb
