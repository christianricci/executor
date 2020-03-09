require 'optparse'
require 'optparse/time'
require 'ostruct'
require 'pp'
require 'pry-byebug'

class Optparse
  attr_reader :parser, :options

  class ScriptOptions
    attr_accessor :run_option, :db_lock_wait, :debug,
                  :load_file, :batch_size, :batch_slice, :status, :inprogress_to_pending

    def initialize
      self.run_option = nil
      self.db_lock_wait = 0.1
      self.debug = false
      self.batch_size = 6
      self.batch_slice = 2
      self.load_file = '/tmp/tracker.file'
    end

    def define_options(parser)
        parser.banner = "Usage:"
        parser.separator ""
        parser.separator "Specific options:"
        parser.on("--run-option OPTION",
                  "Specify the name of the option, [load_tracker|process_batch]"
                 ) do |option|
          self.run_option = option
        end
        parser.separator ""
        parser.separator "Specific options for load_tracker:"
        parser.on("--status",
                  "Provide number of rows status in the tracker",
                  "Does not load any data"
                 ) do |status|
          self.status = status
        end

        parser.on("--inprogress_to_pending",
                  "Change IN-PROGRESS rows BACK to PENDING",
                  "This allows reprocessing of stuck rows."
                 ) do |inprogress_to_pending|
          self.inprogress_to_pending = inprogress_to_pending
        end

        parser.separator ""
        parser.separator "Specific options for process_batch:"
        parser.on("--batch-size SIZE",
                  "Number of batches to process",
                  "Default value: 6"
                 ) do |size|
          self.batch_size = size
        end
        parser.on("--batch-slice SLICE",
                  "Number of elements to be processed by each batch in parallel",
                  "Default value: 2"
                 ) do |slice|
          self.batch_slice = slice
        end

        parser.separator ""
        parser.separator "Common options:"
        # No argument, shows at tail.  This will print an options summary.
        parser.on("--load-file FILE",
                  "Full path to a file",
                  "each line in the file must be a valid json"
                 ) do |file|
          self.load_file = file
        end
        parser.on_tail("--db-lock-wait WAIT",
                  "Time in seconds to wait for transactions. ex 0.5",
                  "Default name: 0.1"
                 ) do |lock|
          lock == 0 ? self.db_lock_wait = 0.1 : self.db_lock_wait = lock
        end
        parser.on_tail("--debug",
                  "Enable debug messaging.",
                  "Default name: false"
                 ) do |debug|
          self.debug = true
        end

        parser.on_tail("-h", "--help", "Show this message") do
        puts parser
        exit
      end
    end
  end

  #
  # Return a structure describing the options.
  #
  def parse(args)
    # The options specified on the command line will be collected in
    # *options*.

    @options = ScriptOptions.new
    @args = OptionParser.new do |parser|
      @options.define_options(parser)
      parser.parse!(args)
    end

    raise OptionParser::InvalidOption if @options.run_option&.match(/^load_tracker$|^process_batch$/).nil?

    @options
  rescue OptionParser::InvalidOption, OptionParser::MissingArgument => e
    puts "[Error] #{e.message}"
    ScriptOptions.new.define_options(OptionParser.new).parse('-h')
  end
end

# ----- How to use it -----
# opt = Optparse.new
# options = opt.parse(ARGV)
#
# pp options
# pp ARGV
