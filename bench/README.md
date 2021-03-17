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
cider            264.42        3.78 ms     ±9.20%        3.70 ms        5.10 ms
remote_ip        257.23        3.89 ms     ±7.23%        3.90 ms        4.95 ms
inet_cidr        229.92        4.35 ms     ±7.60%        4.34 ms        5.74 ms
cidr             166.83        5.99 ms     ±6.58%        6.01 ms        7.73 ms

Comparison: 
cider            264.42
remote_ip        257.23 - 1.03x slower +0.106 ms
inet_cidr        229.92 - 1.15x slower +0.57 ms
cidr             166.83 - 1.58x slower +2.21 ms

##### With input medium #####
Name                ips        average  deviation         median         99th %
remote_ip        3.15 K      317.66 μs    ±14.99%      307.98 μs      512.19 μs
cider            3.12 K      320.40 μs    ±16.06%      314.98 μs      545.98 μs
inet_cidr        2.83 K      353.39 μs    ±13.97%      343.98 μs      555.98 μs
cidr             1.96 K      510.75 μs    ±12.78%      503.98 μs      784.80 μs

Comparison: 
remote_ip        3.15 K
cider            3.12 K - 1.01x slower +2.73 μs
inet_cidr        2.83 K - 1.11x slower +35.73 μs
cidr             1.96 K - 1.61x slower +193.08 μs

##### With input small #####
Name                ips        average  deviation         median         99th %
remote_ip       29.83 K       33.53 μs    ±31.87%       30.98 μs       75.98 μs
cider           29.12 K       34.33 μs    ±31.00%       32.98 μs       76.98 μs
inet_cidr       26.50 K       37.73 μs    ±32.27%       34.98 μs       85.98 μs
cidr            18.29 K       54.69 μs    ±25.17%       51.98 μs      124.98 μs

Comparison: 
remote_ip       29.83 K
cider           29.12 K - 1.02x slower +0.81 μs
inet_cidr       26.50 K - 1.13x slower +4.21 μs
cidr            18.29 K - 1.63x slower +21.16 μs
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
inet_cidr          6.66      150.12 ms     ±1.92%      150.24 ms      156.81 ms
remote_ip          6.54      152.80 ms     ±3.16%      153.86 ms      164.34 ms
cider              3.07      325.50 ms     ±3.14%      326.41 ms      349.31 ms
cidr               1.51      661.99 ms     ±2.12%      666.88 ms      678.52 ms

Comparison: 
inet_cidr          6.66
remote_ip          6.54 - 1.02x slower +2.68 ms
cider              3.07 - 2.17x slower +175.38 ms
cidr               1.51 - 4.41x slower +511.87 ms

##### With input medium #####
Name                ips        average  deviation         median         99th %
remote_ip         70.40       14.21 ms     ±4.74%       14.24 ms       16.25 ms
inet_cidr         66.34       15.07 ms     ±5.03%       15.08 ms       17.49 ms
cider             32.54       30.73 ms     ±7.16%       30.25 ms       38.42 ms
cidr              15.62       64.01 ms     ±5.05%       64.44 ms       79.03 ms

Comparison: 
remote_ip         70.40
inet_cidr         66.34 - 1.06x slower +0.87 ms
cider             32.54 - 2.16x slower +16.53 ms
cidr              15.62 - 4.51x slower +49.81 ms

##### With input small #####
Name                ips        average  deviation         median         99th %
remote_ip        675.19        1.48 ms     ±9.78%        1.48 ms        2.07 ms
inet_cidr        630.73        1.59 ms     ±9.63%        1.57 ms        2.14 ms
cider            331.47        3.02 ms     ±8.42%        2.98 ms        4.02 ms
cidr             158.19        6.32 ms     ±6.65%        6.31 ms        8.21 ms

Comparison: 
remote_ip        675.19
inet_cidr        630.73 - 1.07x slower +0.104 ms
cider            331.47 - 2.04x slower +1.54 ms
cidr             158.19 - 4.27x slower +4.84 ms
```
