# executor
Generic code parallel execution and resume execution from a csv file  

# setup

1 - create a csv file that contains the list of arguments to run. The idea is that each line is executed in batches in parallel. The line data is pass to the run method used as parameters. (see exmaple sample_tracker.csv)

2 - Modify executor.rb and add your code as required. This is the code to be executed in parallel everytime a line is accessed.

```
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
```

# run instructions

```
ruby ./executor.rb -h
Usage:

Specific options:
        --run-option OPTION          Specify the name of the option, [load_tracker|process_batch]

Specific options for load_tracker:
        --status                     Provide number of rows status in the tracker
                                     Does not load any data

Specific options for process_batch:
        --batch-size SIZE            Number of batches to process
                                     Default value: 6
        --batch-slice SLICE          Number of elements to be processed by each batch in parallel
                                     Default value: 2

Common options:
        --load-file FILE             Full path to a file
                                     each line in the file must be a valid json
        --db-lock-wait WAIT          Time in seconds to wait for transactions. ex 0.5
                                     Default name: 0.1
        --debug                      Enable debug messaging.
                                     Default name: false
    -h, --help                       Show this message

ruby ./executor.rb --run-option load_tracker --load-file sample_tracker.csv --debug
[2020-03-09 05:24:48 UTC] [debug] added {"data":"{\"instance_id\":\"001\",\"host_id\":\"100\"}\n"}
[2020-03-09 05:24:48 UTC] [debug] added {"data":"{\"instance_id\":\"002\",\"host_id\":\"200\"}\n"}
[2020-03-09 05:24:48 UTC] [debug] added {"data":"{\"instance_id\":\"003\",\"host_id\":\"300\"}\n"}
[2020-03-09 05:24:48 UTC] [debug] added {"data":"{\"instance_id\":\"004\",\"host_id\":\"400\"}\n"}
[2020-03-09 05:24:48 UTC] [debug] added {"data":"{\"instance_id\":\"005\",\"host_id\":\"500\"}\n"}
[2020-03-09 05:24:48 UTC] [debug] added {"data":"{\"instance_id\":\"006\",\"host_id\":\"600\"}\n"}

ruby ./executor.rb --run-option load_tracker --load-file sample_tracker.csv --status
[["PENDING", 6]]

(20-03-09 5:25:58) <0> [~/workspace/riccic-OpsTools/src/Riccic-OpsToolsRuby/bin/executor]
dev-dsk-riccic-2a-11b4d9f6 % rubyenv ruby ./executor.rb --run-option process_batch --load-file sample_tracker.csv --batch-size 6 --batch-slice 2 --debug
[2020-03-09 05:26:24 UTC] -> Batch #1
[2020-03-09 05:26:24 UTC] [debug] processing line: [["{\"data\":\"{\\\"instance_id\\\":\\\"001\\\",\\\"host_id\\\":\\\"100\\\"}\\n\"}"]]
{"instance_id":"001","host_id":"100"}
[2020-03-09 05:26:24 UTC] [debug] processing line: [["{\"data\":\"{\\\"instance_id\\\":\\\"002\\\",\\\"host_id\\\":\\\"200\\\"}\\n\"}"]]
{"instance_id":"002","host_id":"200"}
[2020-03-09 05:26:25 UTC] -> Tracker status: [["PENDING", 4], ["PROCESSED", 2]]
[2020-03-09 05:26:25 UTC] -> Batch #2
[2020-03-09 05:26:25 UTC] [debug] processing line: [["{\"data\":\"{\\\"instance_id\\\":\\\"003\\\",\\\"host_id\\\":\\\"300\\\"}\\n\"}"]]
[2020-03-09 05:26:25 UTC] [debug] processing line: [["{\"data\":\"{\\\"instance_id\\\":\\\"004\\\",\\\"host_id\\\":\\\"400\\\"}\\n\"}"]]
{"instance_id":"003","host_id":"300"}
{"instance_id":"004","host_id":"400"}
[2020-03-09 05:26:25 UTC] -> Tracker status: [["PENDING", 2], ["PROCESSED", 4]]
[2020-03-09 05:26:25 UTC] -> Batch #3
[2020-03-09 05:26:25 UTC] [debug] processing line: [["{\"data\":\"{\\\"instance_id\\\":\\\"005\\\",\\\"host_id\\\":\\\"500\\\"}\\n\"}"]]
[2020-03-09 05:26:25 UTC] [debug] processing line: [["{\"data\":\"{\\\"instance_id\\\":\\\"006\\\",\\\"host_id\\\":\\\"600\\\"}\\n\"}"]]
{"instance_id":"005","host_id":"500"}
{"instance_id":"006","host_id":"600"}
[2020-03-09 05:26:25 UTC] -> Tracker status: [["PROCESSED", 6]]
```
