require_relative 'progress_tracker'
require 'pry-byebug'
require 'thread'
require 'thwait'

class Paralelizer
  def initialize(ops = {})
    @tracker = ProgressTracker.new(load_file: ops[:load_file],
                                   debug: ops[:debug] || false)
    @class_name = ops[:class_name]
    @class_method = ops[:class_method]
  end

  def process_batch(opts = {})
    batch_slice = opts[:batch_slice].to_i || 10
    batch_size = opts[:batch_size].to_i || 0

    (1..batch_size).each_slice(batch_slice).with_index do |batch, index|
    puts "[#{Time.now.utc}] -> Batch ##{index+1}"
    threads = []
      batch.each do |entry|
        element = @tracker.next
        exit if element.empty?
        threads.push(Thread.new{
          @class_name.send @class_method, element
          @tracker.save(element)
        })
      end
      ThreadsWait.all_waits(threads)
      puts "[#{Time.now.utc}] -> Tracker status: #{@tracker.count}"
    end
  end  
end
