# Benchmarks

For the purposes of remote\_ip, we need a library to (1) parse strings from CIDR notation into a usable representation for (2) checking if an IP falls within a certain block. At the time of this writing, there are a couple [CIDR libraries](https://hex.pm/packages?search=cidr) available on Hex.pm:

* [inet\_cidr](https://hex.pm/packages/inet_cidr)
* [erl\_cidr](https://hex.pm/packages/erl_cidr) (an Erlang wrapper around inet\_cidr)
* [cidr](https://hex.pm/packages/cidr)
* [cider](https://hex.pm/packages/cider)

Due to the shortcomings of these libraries, remote\_ip rolls its own `RemoteIp.Block` module. This app serves as a testing ground for comparing remote\_ip's implementation against the others to validate whether it's actually an improvement.

## Results

### Parsing CIDRs

This benchmark generates varying numbers of random CIDR strings and measures the time it takes to parse them with each different library.

```console
$ mix run parse.exs
Randomizing with seed 828867

Operating System: macOS
CPU Information: Intel(R) Core(TM) i5-1038NG7 CPU @ 2.00GHz
Number of Available Cores: 8
Available memory: 16 GB
Elixir 1.11.4
Erlang 23.2.7

Benchmark suite executing with the following configuration:
warmup: 2 s
time: 5 s
memory time: 0 ns
parallel: 1
inputs: large, medium, small
Estimated total run time: 1.40 min

Benchmarking cider with input large...
Benchmarking cider with input medium...
Benchmarking cider with input small...
Benchmarking cidr with input large...
Benchmarking cidr with input medium...
Benchmarking cidr with input small...
Benchmarking inet_cidr with input large...
Benchmarking inet_cidr with input medium...
Benchmarking inet_cidr with input small...
Benchmarking remote_ip with input large...
Benchmarking remote_ip with input medium...
Benchmarking remote_ip with input small...

##### With input large #####
Name                ips        average  deviation         median         99th %
remote_ip        269.37        3.71 ms     ±6.78%        3.66 ms        5.03 ms
cider            249.10        4.01 ms     ±9.59%        3.92 ms        5.46 ms
inet_cidr        224.87        4.45 ms     ±5.54%        4.38 ms        5.48 ms
cidr             160.27        6.24 ms     ±4.31%        6.16 ms        7.22 ms

Comparison: 
remote_ip        269.37
cider            249.10 - 1.08x slower +0.30 ms
inet_cidr        224.87 - 1.20x slower +0.73 ms
cidr             160.27 - 1.68x slower +2.53 ms

##### With input medium #####
Name                ips        average  deviation         median         99th %
remote_ip        3.09 K      323.96 μs    ±11.28%         317 μs         487 μs
cider            2.93 K      341.25 μs    ±19.22%         324 μs      582.11 μs
inet_cidr        2.76 K      362.50 μs    ±13.18%         355 μs      569.28 μs
cidr             1.93 K      517.99 μs     ±9.41%         507 μs      738.56 μs

Comparison: 
remote_ip        3.09 K
cider            2.93 K - 1.05x slower +17.29 μs
inet_cidr        2.76 K - 1.12x slower +38.54 μs
cidr             1.93 K - 1.60x slower +194.03 μs

##### With input small #####
Name                ips        average  deviation         median         99th %
remote_ip       29.97 K       33.37 μs    ±32.23%          31 μs          71 μs
cider           28.35 K       35.27 μs    ±31.02%          33 μs          76 μs
inet_cidr       26.25 K       38.09 μs    ±30.65%          35 μs       80.94 μs
cidr            18.06 K       55.37 μs    ±23.19%          52 μs         108 μs

Comparison: 
remote_ip       29.97 K
cider           28.35 K - 1.06x slower +1.90 μs
inet_cidr       26.25 K - 1.14x slower +4.72 μs
cidr            18.06 K - 1.66x slower +22.00 μs
```

### Checking IPs

To avoid conflating the parsing & checking performance, we parse a random list of 1,000 CIDRs ahead of time with each library. Then, for each library, we measure how long it takes to check a varying number of IPs against *all* of the library's corresponding parsed CIDRs.

```console
$ mix run check.exs
Randomizing with seed 366209

Operating System: macOS
CPU Information: Intel(R) Core(TM) i5-1038NG7 CPU @ 2.00GHz
Number of Available Cores: 8
Available memory: 16 GB
Elixir 1.11.4
Erlang 23.2.7

Benchmark suite executing with the following configuration:
warmup: 2 s
time: 5 s
memory time: 0 ns
parallel: 1
inputs: large, medium, small
Estimated total run time: 1.40 min

Benchmarking cider with input large...
Benchmarking cider with input medium...
Benchmarking cider with input small...
Benchmarking cidr with input large...
Benchmarking cidr with input medium...
Benchmarking cidr with input small...
Benchmarking inet_cidr with input large...
Benchmarking inet_cidr with input medium...
Benchmarking inet_cidr with input small...
Benchmarking remote_ip with input large...
Benchmarking remote_ip with input medium...
Benchmarking remote_ip with input small...

##### With input large #####
Name                ips        average  deviation         median         99th %
cider             11.10       90.10 ms     ±3.39%       90.51 ms       95.98 ms
remote_ip          6.75      148.19 ms     ±2.27%      147.66 ms      156.78 ms
inet_cidr          6.65      150.38 ms     ±2.66%      150.25 ms      157.34 ms
cidr               1.55      647.23 ms     ±1.11%      649.57 ms      655.39 ms

Comparison: 
cider             11.10
remote_ip          6.75 - 1.64x slower +58.09 ms
inet_cidr          6.65 - 1.67x slower +60.27 ms
cidr               1.55 - 7.18x slower +557.12 ms

##### With input medium #####
Name                ips        average  deviation         median         99th %
cider            112.48        8.89 ms     ±6.23%        8.92 ms       11.09 ms
remote_ip         72.66       13.76 ms     ±6.04%       13.72 ms       16.59 ms
inet_cidr         66.50       15.04 ms     ±4.95%       15.07 ms       17.22 ms
cidr              16.17       61.86 ms     ±3.70%       62.33 ms       66.24 ms

Comparison: 
cider            112.48
remote_ip         72.66 - 1.55x slower +4.87 ms
inet_cidr         66.50 - 1.69x slower +6.15 ms
cidr              16.17 - 6.96x slower +52.97 ms

##### With input small #####
Name                ips        average  deviation         median         99th %
cider           1157.20        0.86 ms    ±10.81%        0.87 ms        1.25 ms
remote_ip        703.21        1.42 ms    ±10.83%        1.41 ms        2.04 ms
inet_cidr        641.30        1.56 ms     ±9.84%        1.55 ms        2.19 ms
cidr             160.31        6.24 ms     ±7.10%        6.24 ms        8.05 ms

Comparison: 
cider           1157.20
remote_ip        703.21 - 1.65x slower +0.56 ms
inet_cidr        641.30 - 1.80x slower +0.70 ms
cidr             160.31 - 7.22x slower +5.37 ms
```
