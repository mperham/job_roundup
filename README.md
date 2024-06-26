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

`bin/rails r bench.rb`

## Results

You'll see something similar to:

```
%  bin/rails r bench.rb                                 
2024-06-26T00:05:53.654Z pid=80843 tid=1jkn INFO: Sidekiq 7.3.0 connecting to Redis with options {:size=>10, :pool_name=>"internal", :url=>nil}
                                user     system      total        real
ruby 3.3.3 (2024-06-12 revision f1c7b6f435) [arm64-darwin23]
{:rails=>"7.1.3.4", :good_job=>"3.29.5", :sidekiq=>"7.3.0", :solid_queue=>"0.3.3"}
Benchmarking with 10000 jobs
good_job-pushbulk           2.055545   0.062931   2.118476 (  2.422912)
good_job-push               7.518458   0.700281   8.218739 ( 14.382432)
sidekiq-push                0.762180   0.112616   0.874796 (  1.082766)
solid_queue-push            6.801042   0.841682   7.642724 ( 13.299562)
sidekiq-native-enq          0.277043   0.064306   0.341349 (  0.493235)
sidekiq-native-enq-bulk     0.061961   0.001396   0.063357 (  0.066778)
```

TODO: Execution profiling?

## Profiling

Something like:

```
bundle exec ruby-prof -p graph_html -m 1 -f profile.html bin/rails -- r bench.rb
```

TODO: Vernier integration?