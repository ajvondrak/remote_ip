defmodule RemoteIp.Headers.Generic do
  @moduledoc """
  Generic parser for forwarding headers.

  When there is no other special `RemoteIp.Headers.*` parser submodule,
  `RemoteIp.Headers.parse/2` will use this module to parse the header value.
  So, `RemoteIp.Headers.Generic` is used to parse `X-Forwarded-For`,
  `X-Real-IP`, `X-Client-IP`, and generally unrecognized headers.
  """

  @doc """
  Parses a comma-separated list of IPs.

  Any amount of whitespace is allowed before and after the commas, as well as
  at the beginning/end of the input.

  ## Examples

      iex> RemoteIp.Headers.Generic.parse("1.2.3.4, 5.6.7.8")
      [{1, 2, 3, 4}, {5, 6, 7, 8}]

      iex> RemoteIp.Headers.Generic.parse("  ::1  ")
      [{0, 0, 0, 0, 0, 0, 0, 1}]

      iex> RemoteIp.Headers.Generic.parse("invalid")
      []
  """

  @type header :: String.t
  @type ip :: :inet.ip_address
  @spec parse(header) :: [ip]

  def parse(header) when is_binary(header) do
    header
    |> split_commas
    |> parse_ips
  end

  defp split_commas(header) do
    header |> String.trim |> String.split(~r/\s*,\s*/)
  end

  defp parse_ips(strings) do
    Enum.reduce(strings, [], fn string, ips ->
      case parse_ip(string) do
        {:ok, ip}                  -> [ip | ips]
        {:error, :einval}          -> ips
        {:error, :invalid_unicode} -> ips
      end
    end) |> Enum.reverse
  end

  defp parse_ip(string) do
    try do
      string |> to_charlist |> :inet.parse_strict_address
    rescue
      UnicodeConversionError -> {:error, :invalid_unicode}
    end
  end
end
