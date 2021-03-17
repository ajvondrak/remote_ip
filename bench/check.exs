Bench.Inputs.seed

cidrs = Bench.Inputs.cidrs(1_000)

blocks = %{
  remote_ip: Enum.map(cidrs, &RemoteIp.Block.parse!/1),
  inet_cidr: Enum.map(cidrs, &InetCidr.parse(&1, true)),
  cider: Enum.map(cidrs, &Cider.parse/1),
  cidr: Enum.map(cidrs, &CIDR.parse/1),
}

suite = %{
  remote_ip: {
    fn ips ->
      Enum.each(ips, fn ip ->
        Enum.each(blocks[:remote_ip], &RemoteIp.Block.contains?(&1, ip))
      end)
    end,
    before_scenario: fn ips ->
      Enum.map(ips, &RemoteIp.Block.encode/1)
    end,
  },
  inet_cidr: fn ips ->
    Enum.each(ips, fn ip ->
      Enum.each(blocks[:inet_cidr], &InetCidr.contains?(&1, ip))
    end)
  end,
  cider: {
    fn ips ->
      Enum.each(ips, fn ip ->
        Enum.each(blocks[:cider], &Cider.contains?(ip, &1))
      end)
    end,
    before_scenario: fn ips ->
      Enum.map(ips, &Cider.ip!/1)
    end,
  },
  cidr: fn ips ->
    Enum.each(ips, fn ip ->
      Enum.each(blocks[:cidr], &CIDR.match(&1, ip))
    end)
  end,
}

inputs = %{
  small: Bench.Inputs.ips(10),
  medium: Bench.Inputs.ips(100),
  large: Bench.Inputs.ips(1_000),
}

Benchee.run(suite, inputs: inputs)
