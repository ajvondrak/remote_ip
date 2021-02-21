defmodule RemoteIp.Options do
  # TODO
  @moduledoc false

  def default(:headers), do: ~w[forwarded x-forwarded-for x-client-ip x-real-ip]
  def default(:parsers), do: %{"forwarded" => RemoteIp.Parsers.Forwarded}
  def default(:proxies), do: []
  def default(:clients), do: []

  def pack(options) do
    [
      headers: pack(options, :headers),
      parsers: pack(options, :parsers),
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
      headers: unpack(options, :headers),
      parsers: unpack(options, :parsers),
      proxies: unpack(options, :proxies),
      clients: unpack(options, :clients)
    ]
  end

  defp unpack(options, option) do
    case Keyword.get(options, option) do
      {m, f, a} -> evaluate(option, apply(m, f, a))
      value -> value
    end
  end

  defp evaluate(:headers, headers), do: headers
  defp evaluate(:parsers, parsers), do: Map.merge(default(:parsers), parsers)
  defp evaluate(:proxies, proxies), do: proxies |> Enum.map(&InetCidr.parse/1)
  defp evaluate(:clients, clients), do: clients |> Enum.map(&InetCidr.parse/1)
end
