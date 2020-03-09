require_relative 'lib/progress_tracker'
require_relative 'lib/paralelizer'
require_relative 'lib/opt_parser'
require 'json'
require 'pry-byebug'

#
# Usage:
#
# --- Load data from file ---
# ruby executor.rb --run-option load_tracker --db-lock-wait 0.1 --load-file /Users/riccic/Downloads/v2_IAD.csv
# --- Get status of load
# ruby executor.rb --run-option load_tracker --db-lock-wait 0.1 --load-file /Users/riccic/Downloads/v2_IAD.csv --status
# 
# --- Process each data element (1 only) ---
# ruby executor.rb --run-option process_batch --db-lock-wait 0.1 --batch-size 1 --batch-slice 1 --debug --load-file /Users/riccic/Downloads/v2_IAD.csv
#
# --- Process each data element (process 1000 elements in total, 10 elements in parallel mode ) ---
# ruby executor.rb --run-option process_batch --db-lock-wait 0.1 --batch-size 1000 --batch-slice 10 --debug --load-file /Users/riccic/Downloads/v2_IAD.csv
#
class Executor
  def self.execute(data_element)
    #
    # ----- Code START here ----
    # Add the block of code to be executed in parallel mode
    #
    # Extract the line content being processed
    line = JSON.parse(data_element)['data'].chomp
    puts "#{line}"
    #
    # ----- Code END here ----
    #
  end

  def self.process_batch(params)
    p = Paralelizer.new(load_file: params.load_file,
                        db_lock_wait: params.db_lock_wait,
                        debug: params.debug,
                        class_name: Executor,
                        class_method: :execute)

    p.process_batch(batch_size: params.batch_size,
                    batch_slice: params.batch_slice)
  end

  def self.load_tracker(params)
    t = ProgressTracker.new(load_file: params.load_file,
                            db_lock_wait: params.db_lock_wait,
                            debug: params.debug)

    if params.inprogress_to_pending
      t.inprogress_to_pending
      puts "#{t.count}"
    end

    if params.status
      puts "#{t.count}"
    else
      t.clean_tracker
      t.create_tracker

      f = File.open(params.load_file, 'r')
      f.each do |line|
        j = { data: line.to_s }
        t.add(j.to_json)
      end
    end
  end

  def self.get_params
    opt = Optparse.new
    options = opt.parse(ARGV)
  end
end 

params = Executor.get_params

case params.run_option
when 'load_tracker'
  Executor.load_tracker(params)
when 'process_batch'
  Executor.process_batch(params)
end
