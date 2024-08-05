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
```

## Run the Benchmarks

```
bin/bench
```

## Results

You'll see something similar to:

```
$ bin/bench

ruby 3.3.4 (2024-07-09 revision be1089c8ec) +YJIT [arm64-darwin23]
{:rails=>"7.1.3.4", :good_job=>"3.29.5", :sidekiq=>"7.2.4", :solid_queue=>"0.3.3"}
Benchmarking with 1000 jobs per iteration
==== Single Enqueue ====
Warming up --------------------------------------
            good_job      2.270 i/s -       3.000 times in 1.321639s (440.55ms/i)
         solid_queue      1.711 i/s -       2.000 times in 1.168985s (584.49ms/i)
             sidekiq     16.484 i/s -      18.000 times in 1.091964s (60.66ms/i)
      sidekiq-native     26.912 i/s -      27.000 times in 1.003259s (37.16ms/i)
Calculating -------------------------------------
            good_job      2.218 i/s -       6.000 times in 2.705422s (450.90ms/i)
         solid_queue      1.611 i/s -       5.000 times in 3.103893s (620.78ms/i)
             sidekiq     16.159 i/s -      49.000 times in 3.032280s (61.88ms/i)
      sidekiq-native     26.112 i/s -      80.000 times in 3.063720s (38.30ms/i)

Comparison:
      sidekiq-native:        26.1 i/s
             sidekiq:        16.2 i/s - 1.62x  slower
            good_job:         2.2 i/s - 11.77x  slower
         solid_queue:         1.6 i/s - 16.21x  slower

==== Bulk Enqueue ====
Warming up --------------------------------------
            good_job      7.671 i/s -       8.000 times in 1.042856s (130.36ms/i)
             sidekiq     82.011 i/s -      88.000 times in 1.073021s (12.19ms/i)
      sidekiq-native    180.868 i/s -     190.000 times in 1.050491s (5.53ms/i)
Calculating -------------------------------------
            good_job      7.192 i/s -      23.000 times in 3.198037s (139.05ms/i)
             sidekiq     80.518 i/s -     246.000 times in 3.055228s (12.42ms/i)
      sidekiq-native    179.980 i/s -     542.000 times in 3.011441s (5.56ms/i)

Comparison:
      sidekiq-native:       180.0 i/s
             sidekiq:        80.5 i/s - 2.24x  slower
            good_job:         7.2 i/s - 25.03x  slower
```

TODO: Execution profiling?

## Profiling

Something like:

```
bundle exec ruby-prof -p graph_html -m 1 -f profile.html bin/rails -- r bench.rb
```

TODO: Vernier integration?