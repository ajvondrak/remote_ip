defmodule RemoteIp.Headers do
  @moduledoc """
  Entry point for parsing any type of forwarding header.
  """

  require Logger

  @doc  """
  Selects the appropriate headers and parses IPs out of them.

  * `headers` - The entire list of the `Plug.Conn` `req_headers`
  * `allowed` - The list of headers `RemoteIp` is configured to look for,
    converted to a `MapSet` for efficiency

  The actual parsing is delegated to the `RemoteIp.Headers.*` submodules:

  * `"forwarded"` is parsed by `RemoteIp.Headers.Forwarded`
  * everything else is parsed by `RemoteIp.Headers.Generic`
  """

  @type key :: String.t
  @type value :: String.t
  @type header :: {key, value}
  @type allowed :: %MapSet{}
  @type ip :: :inet.ip_address

  @spec parse([header], allowed) :: [ip]

  def parse(headers, %MapSet{} = allowed) when is_list(headers) do
    Logger.debug(fn -> parsing(headers) end)
    ips = headers |> allow(allowed) |> parse_each
    Logger.debug(fn -> parsed(ips) end)
    ips
  end

  defp allow(headers, allowed) do
    filtered = Enum.filter(headers, &allow?(&1, allowed))
    Logger.debug(fn -> considering(filtered) end)
    filtered
  end

  defp allow?({header, _}, allowed) do
    MapSet.member?(allowed, header)
  end

  defp parse_each(headers) do
    Enum.flat_map(headers, &parse_ips/1)
  end

  defp parse_ips({"forwarded", value}) when is_binary(value) do
    RemoteIp.Headers.Forwarded.parse(value)
  end

  defp parse_ips({header, value}) when is_binary(header) and is_binary(value) do
    RemoteIp.Headers.Generic.parse(value)
  end

  defp parsing(req_headers) do
    [
      inspect(__MODULE__),
      " is parsing IPs from the request headers ",
      inspect(req_headers, pretty: true)
    ]
  end

  def considering(req_headers) do
    [
      inspect(__MODULE__),
      " is only considering the request headers ",
      inspect(req_headers, pretty: true)
    ]
  end

  defp parsed(ips) do
    [
      inspect(__MODULE__),
      " parsed the request headers into the IPs ",
      inspect(ips, pretty: true)
    ]
  end
end
