defmodule RemoteIp.Block do
  import Bitwise
  alias __MODULE__

  @moduledoc false

  defstruct [:proto, :net, :mask]

  def encode({a, b, c, d}) do
    <<ip::32>> = <<a::8, b::8, c::8, d::8>>
    {:v4, ip}
  end

  def encode({a, b, c, d, e, f, g, h}) do
    <<ip::128>> = <<a::16, b::16, c::16, d::16, e::16, f::16, g::16, h::16>>
    {:v6, ip}
  end

  def contains?(%Block{proto: proto, net: net, mask: mask}, {proto, ip}) do
    (ip &&& mask) == net
  end

  def contains?(%Block{}, {_, _}) do
    false
  end

  def parse!(cidr) do
    case parse(cidr) do
      {:ok, block} -> block
      {:error, message} -> raise ArgumentError, message
    end
  end

  def parse(cidr) do
    case process(:parts, String.split(cidr, "/", parts: 2)) do
      {:error, e} -> {:error, "#{e} in CIDR #{inspect(cidr)}"}
      ok -> ok
    end
  end

  defp process(:parts, [ip, prefix]) do
    with {:ok, ip} <- process(:ip, ip),
         {:ok, prefix} <- process(:prefix, prefix) do
      process(:block, ip, prefix)
    end
  end

  defp process(:parts, [ip]) do
    with {:ok, ip} <- process(:ip, ip) do
      process(:block, ip)
    end
  end

  defp process(:ip, address) do
    case :inet.parse_strict_address(address |> to_charlist()) do
      {:ok, ip} -> {:ok, encode(ip)}
      {:error, _} -> {:error, "Invalid address #{inspect(address)}"}
    end
  end

  defp process(:prefix, prefix) do
    try do
      {:ok, String.to_integer(prefix)}
    rescue
      ArgumentError -> {:error, "Invalid prefix #{inspect(prefix)}"}
    end
  end

  defp process(:block, {:v4, ip}) do
    process(:block, {:v4, ip}, 32)
  end

  defp process(:block, {:v6, ip}) do
    process(:block, {:v6, ip}, 128)
  end

  defp process(:block, {:v4, ip}, prefix) when prefix in 0..32 do
    ones = 0xFFFFFFFF
    <<mask::32>> = <<(~~~(ones >>> prefix))::32>>
    {:ok, %Block{proto: :v4, net: ip &&& mask, mask: mask}}
  end

  defp process(:block, {:v6, ip}, prefix) when prefix in 0..128 do
    ones = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
    <<mask::128>> = <<(~~~(ones >>> prefix))::128>>
    {:ok, %Block{proto: :v6, net: ip &&& mask, mask: mask}}
  end

  defp process(:block, _, prefix) do
    {:error, "Invalid prefix #{inspect(prefix)}"}
  end

  defimpl String.Chars, for: Block do
    def to_string(%Block{proto: :v4, net: net, mask: mask}) do
      <<a::8, b::8, c::8, d::8>> = <<net::32>>
      "#{:inet.ntoa({a, b, c, d})}/#{bits(mask)}"
    end

    def to_string(%Block{proto: :v6, net: net, mask: mask}) do
      <<a::16, b::16, c::16, d::16, e::16, f::16, g::16, h::16>> = <<net::128>>
      "#{:inet.ntoa({a, b, c, d, e, f, g, h})}/#{bits(mask)}"
    end

    defp bits(mask) do
      ones = for <<1::1 <- :binary.encode_unsigned(mask)>>, do: 1
      length(ones)
    end
  end
end
