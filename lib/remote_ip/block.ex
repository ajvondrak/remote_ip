defmodule RemoteIp.Block do
  use Bitwise
  alias __MODULE__

  @moduledoc false

  defstruct [:ip, :mask]

  def encode({a, b, c, d}) do
    <<a::8, b::8, c::8, d::8>>
  end

  def encode({a, b, c, d, e, f, g, h}) do
    <<a::16, b::16, c::16, d::16, e::16, f::16, g::16, h::16>>
  end

  def contains?(%Block{} = block, ip) when is_tuple(ip) do
    contains?(block, encode(ip))
  end

  def contains?(%Block{ip: <<sup::32>>, mask: <<mask::32>>}, <<sub::32>>) do
    (sup &&& mask) == (sub &&& mask)
  end

  def contains?(%Block{ip: <<sup::128>>, mask: <<mask::128>>}, <<sub::128>>) do
    (sup &&& mask) == (sub &&& mask)
  end

  def contains?(%Block{}, _) do
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
      process(:block, ip, bit_size(ip))
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

  defp process(:block, <<_::32>> = ip, prefix) when prefix in 0..32 do
    ones = 0xFFFFFFFF
    {:ok, %Block{ip: ip, mask: <<(~~~(ones >>> prefix))::32>>}}
  end

  defp process(:block, <<_::128>> = ip, prefix) when prefix in 0..128 do
    ones = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
    {:ok, %Block{ip: ip, mask: <<(~~~(ones >>> prefix))::128>>}}
  end

  defp process(:block, _, prefix) do
    {:error, "Invalid prefix #{inspect(prefix)}"}
  end
end
