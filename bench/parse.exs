Bench.Inputs.seed

suite = %{
  remote_ip: fn inputs -> Enum.each(inputs, &RemoteIp.Block.parse!/1) end,
  inet_cidr: fn inputs -> Enum.each(inputs, &InetCidr.parse(&1, true)) end,
  cider: fn inputs -> Enum.each(inputs, &Cider.parse/1) end,
  cidr: fn inputs -> Enum.each(inputs, &CIDR.parse/1) end,
}

inputs = %{
  small: Bench.Inputs.cidrs(10),
  medium: Bench.Inputs.cidrs(100),
  large: Bench.Inputs.cidrs(1_000),
}

Benchee.run(suite, inputs: inputs)
