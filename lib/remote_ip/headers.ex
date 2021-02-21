defmodule RemoteIp.Headers do
  @moduledoc """
  Functions for parsing IPs from multiple types of forwarding headers.
  """

  @doc """
  Extracts all headers with the given names.

  Note that `Plug.Conn` headers are assumed to have been normalized to
  lowercase, so the names you give should be in lowercase as well.

  ## Examples

      iex> [{"x-foo", "foo"}, {"x-bar", "bar"}, {"x-baz", "baz"}]
      ...> |> RemoteIp.Headers.take(["x-foo", "x-baz", "x-qux"])
      [{"x-foo", "foo"}, {"x-baz", "baz"}]

      iex> [{"x-dup", "foo"}, {"x-dup", "bar"}, {"x-dup", "baz"}]
      ...> |> RemoteIp.Headers.take(["x-dup"])
      [{"x-dup", "foo"}, {"x-dup", "bar"}, {"x-dup", "baz"}]
  """

  @spec take(Plug.Conn.headers(), [binary()]) :: Plug.Conn.headers()

  def take(headers, names) do
    Enum.filter(headers, fn {name, _} -> name in names end)
  end

  @doc """
  Parses IP addresses out of the given headers.

  For each header name/value pair, the value is parsed for zero or more IP
  addresses by the parser corresponding to the name. If no such parser exists
  in the given map, we fall back to `RemoteIp.Parsers.Generic`.

  The IPs are concatenated together into a single flat list. Note that the
  relative order is preserved. That is, each header produce multiple IPs that
  are kept in the order given by that specific header. Then, in the case of
  multiple headers, the concatenated list maintains the same order as the
  headers appeared in the original name/value list.

  Due to the error-safe nature of the parser behaviour, headers that do not
  actually contain valid IP addresses should be safely ignored.

  ## Examples

      iex> [{"x-one", "1.2.3.4, 2.3.4.5"}, {"x-two", "3.4.5.6, 4.5.6.7"}]
      ...> |> RemoteIp.Headers.parse()
      [{1, 2, 3, 4}, {2, 3, 4, 5}, {3, 4, 5, 6}, {4, 5, 6, 7}]

      iex> [{"forwarded", "for=1.2.3.4"}, {"x-forwarded-for", "2.3.4.5"}]
      ...> |> RemoteIp.Headers.parse()
      [{1, 2, 3, 4}, {2, 3, 4, 5}]

      iex> [{"accept", "*/*"}, {"user-agent", "ua"}, {"x-real-ip", "1.2.3.4"}]
      ...> |> RemoteIp.Headers.parse()
      [{1, 2, 3, 4}]
  """

  @spec parse(Plug.Conn.headers(), %{binary() => RemoteIp.Parser.t()}) ::
          [:inet.ip_address()]

  def parse(headers, parsers \\ RemoteIp.Options.default(:parsers)) do
    Enum.flat_map(headers, fn {name, value} ->
      parser = Map.get(parsers, name, RemoteIp.Parsers.Generic)
      parser.parse(value)
    end)
  end
end
