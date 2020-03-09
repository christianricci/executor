require 'sqlite3'
require 'pry-byebug'

# Add it in your ruby code as follows:
# >> require_relative 'progress_tracker'
# --
# To initialize use load_file and it will create a sqlite db file 
# >> tracker = ProgressTracker.new(load_file: 'certs')
# --
# Create the table to store element in PENDING status
# >> tracker.create_tracker
# --
# Add a JSON element into the table, by default status is PENDING
# >> tracker.add('{"key":"value","key1":"value1"}') # it must be a valid json
# --
# List all different status and total count
# >> tracker.count
# --
# Get the next PENDING row from the table and change status to IN-PROGRESS
# >> n = tracker.next
# --
# Modify the status of row to PROCESSED
# >> tracker.save(n)
# List next row in progress, usefull when there are left over in-progress rows
# >> n = tracker.list_next_in_progress
# --
# Drop the table with the name of the initialized variable load_file
# >> tracker.clean_tracker

class ProgressTracker
  def initialize(opts = {})
    @load_file = opts[:load_file]
    @debug = opts[:debug] || false
    @db_lock_wait = opts[:db_lock_wait].to_f || 0.1
    @db_tracker = SQLite3::Database.new "#{@load_file}.db"
    @tracker_name = 'tracker'
  end

  def add(line)
    insert = nil
    until !insert.nil? do
      begin
        insert = @db_tracker.execute <<-SQL
                   INSERT INTO #{@tracker_name}_tab
                   (status, row)
                   select 'PENDING',json('#{line}')
                   where not exists (
                   select 1
                   from #{@tracker_name}_tab
                   where json(row) = json('#{line}')
                   );
                 SQL
        
        puts "[#{Time.now.utc}] [debug] added #{line}" if @debug
      rescue SQLite3::BusyException => e
        print "."  if @debug
        sleep @db_lock_wait
      end
    end

    true
  rescue SQLite3::SQLException => e
    case e.message 
    when "no such table: #{@tracker_name}"
      puts "[#{Time.now.utc}] [Error] table does not exit, call create method first."
    when 'malformed JSON'
      puts "[#{Time.now.utc}] [Error] #{e.message}"
    else
      raise "[#{Time.now.utc}] [Error] #{e.message}"
    end
  end

  def count
    line = nil
    until !line.nil? do
      begin
        line = @db_tracker.execute <<-SQL
          select status,count(1) as total 
          from #{@tracker_name}_tab
          group by status;
        SQL
      rescue SQLite3::BusyException => e
        print "."  if @debug
        sleep @db_lock_wait
      end
    end
    line
  rescue SQLite3::SQLException => e
    if e.message =~ /no such table:/
      puts "[#{Time.now.utc}] [Error] table does not exit, call create method first."
    else  
      raise "[#{Time.now.utc}] [Error] #{e.message}"
    end
  end

  def next
    select = nil
    until !select.nil? do
      begin
        line = @db_tracker.execute <<-SQL
          select row 
          from #{@tracker_name}_tab
          where
          status = 'PENDING'
          limit 1;
        SQL
        select = line
        puts "[#{Time.now.utc}] [debug] processing line: #{line}"  if @debug
      rescue SQLite3::BusyException => e
        print "."  if @debug
        sleep @db_lock_wait
      end
    end    
    if line.count == 0
      line
    else
      save(line[0][0], 'IN-PROGRESS')
      line[0][0]
    end
  rescue SQLite3::SQLException => e
    if e.message =~ /no such table:/
      puts "[#{Time.now.utc}] [Error] table does not exit, call create method first."
    else  
      raise "[#{Time.now.utc}] [Error] #{e.message}"
    end
  end

  def list_next_in_progress
    line = @db_tracker.execute <<-SQL
      select row 
      from #{@tracker_name}_tab
      where
      status = 'IN-PROGRESS'
      limit 1;
    SQL
    if line.count == 0
      line
    else
      line[0][0]
    end
  rescue SQLite3::SQLException => e
    if e.message =~ /no such table:/
      puts "[#{Time.now.utc}] [Error] table does not exit, call create method first."
    else  
      raise "[#{Time.now.utc}] [Error] #{e.message}"
    end
  end

  def inprogress_to_pending
    line = @db_tracker.execute <<-SQL
      update #{@tracker_name}_tab
      set status = 'PENDING'
      where
      status = 'IN-PROGRESS';
    SQL
    
    true
  rescue SQLite3::SQLException => e
    if e.message =~ /no such table:/
      puts "[#{Time.now.utc}] [Error] table does not exit, call create method first."
    else  
      raise "[#{Time.now.utc}] [Error] #{e.message}"
    end
  end

  def save(line, status = 'PROCESSED')
    update = nil
    until !update.nil? do
      begin
        update = @db_tracker.execute <<-SQL
                   update #{@tracker_name}_tab
                   set status = '#{status}'
                   where json(row) = json('#{line}')
                 SQL
      rescue SQLite3::BusyException => e
        print "." if @debug
        sleep @db_lock_wait
      end
    end

    true
  rescue SQLite3::SQLException => e
    if e.message =~ /no such table:/
      puts "[#{Time.now.utc}] [Error] table does not exit, call create method first."
    else  
      raise "[#{Time.now.utc}] [Error] #{e.message}"
    end
  end

  def clean_tracker
    @db_tracker.execute <<-SQL
      drop table if exists #{@tracker_name}_tab;
    SQL

    true
  end

  def create_tracker
    @db_tracker.execute <<-SQL
      create table if not exists #{@tracker_name}_tab (
        status varchar(100) default 'PENDING',
        row text,
        primary key(row)
      );
    SQL

    true
  end 
end
