defmodule Bench.Inputs do
  def seed do
    seed =
      case System.fetch_env("SEED") do
        {:ok, var} -> String.to_integer(var)
        :error -> System.system_time(:microsecond) |> rem(1_000_000)
      end

    IO.puts("Randomizing with seed #{seed}\n")
    :rand.seed(:exs1024, {seed, seed, seed})
  end

  def cidrs(n) do
    Stream.repeatedly(fn -> cidr() end) |> Enum.take(n)
  end

  def cidr do
    case Enum.random([:ipv4, :ipv6]) do
      :ipv4 -> cidr(ipv4())
      :ipv6 -> cidr(ipv6())
    end
  end

  def cidr({a, b, c, d}) do
    cidr({a, b, c, d}, Enum.random(0..32))
  end

  def cidr({a, b, c, d, e, f, g, h}) do
    cidr({a, b, c, d, e, f, g, h}, Enum.random(0..128))
  end

  def cidr(ip, prefix) do
    "#{:inet.ntoa(ip)}/#{prefix}"
  end

  def ips(n) do
    Stream.repeatedly(fn -> ip() end) |> Enum.take(n)
  end

  def ip do
    case Enum.random([:ipv4, :ipv6]) do
      :ipv4 -> ipv4()
      :ipv6 -> ipv6()
    end
  end

  def ipv4 do
    Stream.repeatedly(fn -> Enum.random(0..255) end)
    |> Enum.take(4)
    |> List.to_tuple()
  end

  def ipv6 do
    Stream.repeatedly(fn -> Enum.random(0..0xFFFF) end)
    |> Enum.take(8)
    |> List.to_tuple()
  end
end
