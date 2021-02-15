defmodule RemoteIp.Options do
  use RemoteIp.Debug

  # TODO
  @moduledoc false

  def default(:headers), do: ~w[forwarded x-forwarded-for x-client-ip x-real-ip]
  def default(:proxies), do: []
  def default(:clients), do: []

  def pack(options) do
    [
      headers: pack(options, :headers),
      proxies: pack(options, :proxies),
      clients: pack(options, :clients)
    ]
  end

  defp pack(options, option) do
    case Keyword.get(options, option, default(option)) do
      {m, f, a} -> {m, f, a}
      value -> evaluate(option, value)
    end
  end

  def unpack(options) do
    [
      headers: RemoteIp.Debug.log(:headers, do: unpack(options, :headers)),
      proxies: RemoteIp.Debug.log(:proxies, do: unpack(options, :proxies)),
      clients: RemoteIp.Debug.log(:clients, do: unpack(options, :clients))
    ]
  end

  defp unpack(options, option) do
    case Keyword.get(options, option) do
      {m, f, a} -> evaluate(option, apply(m, f, a))
      value -> value
    end
  end

  defp evaluate(:headers, headers), do: headers
  defp evaluate(:proxies, proxies), do: proxies |> Enum.map(&InetCidr.parse/1)
  defp evaluate(:clients, clients), do: clients |> Enum.map(&InetCidr.parse/1)
end
