# Job Roundup

Benchmarking various Ruby background job engines.

## To Prepare

```
brew install postgresql@16 redis
bundle
rake db:create
bin/rails g good_job:install
rake solid_queue:install:migrations
rake db:migrate
export RUBY_YJIT_ENABLE=1
```

## Between Runs

```
redis-cli flushall
rake db:drop db:create db:migrate
```

## Run the Benchmarks

```
ruby bench.rb
```

## Results

You'll see something similar to:

```
$ ruby bench.rb
ruby 3.3.3 (2024-06-12 revision f1c7b6f435) [x86_64-linux]
{:rails=>"7.1.3.4", :good_job=>"3.29.5", :sidekiq=>"7.2.4", :solid_queue=>"0.3.3"}
Benchmarking with 1000 jobs per iteration
Warming up --------------------------------------
          good_job-push      0.654 i/s -       1.000 times in 1.529646s (1.53s/i)
      good_job-pushbulk      2.617 i/s -       3.000 times in 1.146226s (382.08ms/i)
       solid_queue-push      0.527 i/s -       1.000 times in 1.898825s (1.90s/i)
           sidekiq-push      7.407 i/s -       8.000 times in 1.079990s (135.00ms/i)
     sidekiq-native-enq     19.492 i/s -      21.000 times in 1.077352s (51.30ms/i)
sidekiq-native-enq-bulk    150.399 i/s -     165.000 times in 1.097080s (6.65ms/i)
Calculating -------------------------------------
          good_job-push      0.668 i/s -       1.000 times in 1.496906s (1.50s/i)
      good_job-pushbulk      2.615 i/s -       7.000 times in 2.676486s (382.36ms/i)
       solid_queue-push      0.505 i/s -       1.000 times in 1.978678s (1.98s/i)
           sidekiq-push      7.750 i/s -      22.000 times in 2.838791s (129.04ms/i)
     sidekiq-native-enq     19.911 i/s -      58.000 times in 2.912960s (50.22ms/i)
sidekiq-native-enq-bulk    148.810 i/s -     451.000 times in 3.030703s (6.72ms/i)

Comparison:
sidekiq-native-enq-bulk:       148.8 i/s
     sidekiq-native-enq:        19.9 i/s - 7.47x  slower
           sidekiq-push:         7.7 i/s - 19.20x  slower
      good_job-pushbulk:         2.6 i/s - 56.90x  slower
          good_job-push:         0.7 i/s - 222.76x  slower
       solid_queue-push:         0.5 i/s - 294.45x  slower
```

TODO: Execution profiling?

## Profiling

Something like:

```
bundle exec ruby-prof -p graph_html -m 1 -f profile.html bin/rails -- r bench.rb
```

TODO: Vernier integration?