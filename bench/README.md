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
cider            257.12        3.89 ms     ±8.66%        3.90 ms        5.70 ms
remote_ip        252.18        3.97 ms     ±8.25%        3.97 ms        5.49 ms
inet_cidr        227.39        4.40 ms     ±7.18%        4.39 ms        5.70 ms
cidr             165.12        6.06 ms     ±6.44%        6.07 ms        7.50 ms

Comparison: 
cider            257.12
remote_ip        252.18 - 1.02x slower +0.0763 ms
inet_cidr        227.39 - 1.13x slower +0.51 ms
cidr             165.12 - 1.56x slower +2.17 ms

##### With input medium #####
Name                ips        average  deviation         median         99th %
cider            3.12 K      320.07 μs    ±14.98%      307.98 μs      518.32 μs
remote_ip        3.07 K      325.41 μs    ±19.04%      314.98 μs      541.98 μs
inet_cidr        2.76 K      362.71 μs    ±15.15%      351.98 μs      594.98 μs
cidr             1.96 K      510.74 μs    ±12.63%      504.98 μs      780.39 μs

Comparison: 
cider            3.12 K
remote_ip        3.07 K - 1.02x slower +5.35 μs
inet_cidr        2.76 K - 1.13x slower +42.64 μs
cidr             1.96 K - 1.60x slower +190.67 μs

##### With input small #####
Name                ips        average  deviation         median         99th %
remote_ip       29.21 K       34.23 μs    ±32.73%       30.98 μs       78.98 μs
cider           28.93 K       34.56 μs    ±30.08%       32.98 μs       77.98 μs
inet_cidr       25.98 K       38.50 μs    ±32.61%       35.98 μs       85.98 μs
cidr            18.25 K       54.80 μs    ±25.68%       52.98 μs      124.98 μs

Comparison: 
remote_ip       29.21 K
cider           28.93 K - 1.01x slower +0.33 μs
inet_cidr       25.98 K - 1.12x slower +4.26 μs
cidr            18.25 K - 1.60x slower +20.57 μs
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
remote_ip         15.17       65.91 ms     ±3.32%       65.95 ms       71.84 ms
cider             11.21       89.18 ms     ±3.01%       89.75 ms       94.94 ms
inet_cidr          6.53      153.13 ms     ±2.67%      153.22 ms      163.81 ms
cidr               1.52      658.38 ms     ±1.21%      654.94 ms      670.14 ms

Comparison: 
remote_ip         15.17
cider             11.21 - 1.35x slower +23.28 ms
inet_cidr          6.53 - 2.32x slower +87.23 ms
cidr               1.52 - 9.99x slower +592.47 ms

##### With input medium #####
Name                ips        average  deviation         median         99th %
remote_ip        152.78        6.55 ms     ±6.32%        6.54 ms        8.05 ms
cider            113.19        8.83 ms     ±5.85%        8.85 ms       10.72 ms
inet_cidr         65.15       15.35 ms     ±4.81%       15.36 ms       17.60 ms
cidr              15.85       63.11 ms     ±3.43%       63.08 ms       67.38 ms

Comparison: 
remote_ip        152.78
cider            113.19 - 1.35x slower +2.29 ms
inet_cidr         65.15 - 2.35x slower +8.80 ms
cidr              15.85 - 9.64x slower +56.56 ms

##### With input small #####
Name                ips        average  deviation         median         99th %
remote_ip        1.55 K        0.64 ms    ±10.79%        0.64 ms        0.92 ms
cider            1.12 K        0.89 ms    ±11.01%        0.89 ms        1.29 ms
inet_cidr        0.63 K        1.59 ms     ±9.59%        1.58 ms        2.21 ms
cidr            0.160 K        6.27 ms     ±6.60%        6.30 ms        8.10 ms

Comparison: 
remote_ip        1.55 K
cider            1.12 K - 1.39x slower +0.25 ms
inet_cidr        0.63 K - 2.47x slower +0.94 ms
cidr            0.160 K - 9.74x slower +5.62 ms
```
