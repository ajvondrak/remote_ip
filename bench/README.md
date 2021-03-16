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
remote_ip        260.95        3.83 ms     ±8.22%        3.83 ms        5.20 ms
cider            253.39        3.95 ms     ±9.17%        3.90 ms        5.45 ms
inet_cidr        222.53        4.49 ms     ±8.11%        4.43 ms        6.03 ms
cidr             158.98        6.29 ms     ±7.26%        6.20 ms        7.76 ms

Comparison: 
remote_ip        260.95
cider            253.39 - 1.03x slower +0.114 ms
inet_cidr        222.53 - 1.17x slower +0.66 ms
cidr             158.98 - 1.64x slower +2.46 ms

##### With input medium #####
Name                ips        average  deviation         median         99th %
remote_ip        3.16 K      316.37 μs    ±14.87%         311 μs      513.55 μs
cider            3.04 K      329.22 μs    ±16.39%         320 μs         566 μs
inet_cidr        2.69 K      371.54 μs    ±15.03%         363 μs      614.02 μs
cidr             1.95 K      513.25 μs    ±13.40%         507 μs      808.89 μs

Comparison: 
remote_ip        3.16 K
cider            3.04 K - 1.04x slower +12.85 μs
inet_cidr        2.69 K - 1.17x slower +55.17 μs
cidr             1.95 K - 1.62x slower +196.88 μs

##### With input small #####
Name                ips        average  deviation         median         99th %
remote_ip       30.66 K       32.61 μs    ±32.67%          30 μs          73 μs
cider           28.13 K       35.56 μs    ±32.31%          33 μs          86 μs
inet_cidr       24.48 K       40.85 μs    ±35.59%          36 μs         104 μs
cidr            17.58 K       56.87 μs    ±26.80%          53 μs         128 μs

Comparison: 
remote_ip       30.66 K
cider           28.13 K - 1.09x slower +2.94 μs
inet_cidr       24.48 K - 1.25x slower +8.24 μs
cidr            17.58 K - 1.74x slower +24.26 μs
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
inet_cidr          6.43      155.51 ms     ±2.23%      155.62 ms      161.35 ms
remote_ip          3.80      263.28 ms     ±2.79%      261.08 ms      289.81 ms
cider              3.02      330.69 ms     ±1.65%      328.73 ms      345.48 ms
cidr               1.51      661.89 ms     ±0.65%      662.68 ms      667.33 ms

Comparison: 
inet_cidr          6.43
remote_ip          3.80 - 1.69x slower +107.77 ms
cider              3.02 - 2.13x slower +175.18 ms
cidr               1.51 - 4.26x slower +506.38 ms

##### With input medium #####
Name                ips        average  deviation         median         99th %
inet_cidr         64.23       15.57 ms     ±5.10%       15.61 ms       18.90 ms
remote_ip         40.02       24.99 ms     ±4.81%       24.96 ms       29.09 ms
cider             32.81       30.48 ms     ±2.32%       30.29 ms       32.50 ms
cidr              15.49       64.54 ms     ±3.07%       64.76 ms       68.52 ms

Comparison: 
inet_cidr         64.23
remote_ip         40.02 - 1.61x slower +9.42 ms
cider             32.81 - 1.96x slower +14.91 ms
cidr              15.49 - 4.15x slower +48.97 ms

##### With input small #####
Name                ips        average  deviation         median         99th %
inet_cidr        616.33        1.62 ms    ±10.50%        1.61 ms        2.34 ms
remote_ip        407.22        2.46 ms     ±8.76%        2.44 ms        3.49 ms
cider            322.58        3.10 ms     ±5.24%        3.05 ms        3.79 ms
cidr             156.20        6.40 ms     ±7.28%        6.42 ms        8.17 ms

Comparison: 
inet_cidr        616.33
remote_ip        407.22 - 1.51x slower +0.83 ms
cider            322.58 - 1.91x slower +1.48 ms
cidr             156.20 - 3.95x slower +4.78 ms
```
