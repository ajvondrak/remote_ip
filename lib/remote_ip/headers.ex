defmodule RemoteIp.Headers do
  @moduledoc """
  Entry point for parsing any type of forwarding header.
  """

  require RemoteIp.Debug

  @doc  """
  Selects the appropriate headers and parses IPs out of them.

  * `headers` - The entire list of the `Plug.Conn` `req_headers`
  * `allowed` - The list of headers `RemoteIp` is configured to look for

  The actual parsing is delegated to the `RemoteIp.Headers.*` submodules:

  * `"forwarded"` is parsed by `RemoteIp.Headers.Forwarded`
  * everything else is parsed by `RemoteIp.Headers.Generic`
  """

  @type key :: String.t
  @type value :: String.t
  @type header :: {key, value}
  @type allowed :: [String.t]
  @type ip :: :inet.ip_address

  @spec parse([header], allowed) :: [ip]

  def parse(headers, allowed) when is_list(headers) do
    RemoteIp.Debug.log(:req, do: headers)
    headers |> allow(allowed) |> parse_each
  end

  defp allow(headers, allowed) do
    RemoteIp.Debug.log(:fwd) do
      Enum.filter(headers, &allow?(&1, allowed))
    end
  end

  defp allow?({header, _}, allowed) do
    Enum.member?(allowed, header)
  end

  defp parse_each(headers) do
    RemoteIp.Debug.log(:ips) do
      Enum.flat_map(headers, &parse_ips/1)
    end
  end

  defp parse_ips({"forwarded", value}) when is_binary(value) do
    RemoteIp.Headers.Forwarded.parse(value)
  end

  defp parse_ips({header, value}) when is_binary(header) and is_binary(value) do
    RemoteIp.Headers.Generic.parse(value)
  end
end
