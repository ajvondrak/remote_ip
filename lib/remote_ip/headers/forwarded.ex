defmodule RemoteIp.Headers.Forwarded do
  @moduledoc """
  [RFC 7239](https://tools.ietf.org/html/rfc7239) compliant parser for
  `Forwarded` headers.
  """

  use Combine

  @doc """
  Given a `Forwarded` header's string value, parses out IP addresses from the
  `for=` parameter.

  ## Examples

      iex> RemoteIp.Headers.Forwarded.parse("for=1.2.3.4;by=2.3.4.5")
      [{1, 2, 3, 4}]

      iex> RemoteIp.Headers.Forwarded.parse("for=\\"[::1]\\", for=\\"[::2]\\"")
      [{0, 0, 0, 0, 0, 0, 0, 1}, {0, 0, 0, 0, 0, 0, 0, 2}]

      iex> RemoteIp.Headers.Forwarded.parse("invalid")
      []
  """

  @type header :: String.t()
  @type ip :: :inet.ip_address()
  @spec parse(header) :: [ip]

  def parse(header) when is_binary(header) do
    case Combine.parse(header, forwarded()) do
      [elements] -> Enum.flat_map(elements, &parse_forwarded_for/1)
      _ -> []
    end
  end

  defp parse_forwarded_for(pairs) do
    case pairs |> fors do
      [string] -> parse_ip(string)
      # no `for=`s or multiple `for=`s
      _ -> []
    end
  end

  defp fors(pairs) do
    for {key, val} <- pairs, String.downcase(key) == "for", do: val
  end

  defp parse_ip(string) do
    case Combine.parse(string, ip_address()) do
      [ip] -> [ip]
      _ -> []
    end
  end

  # https://tools.ietf.org/html/rfc7239#section-4

  defp forwarded do
    sep_by(forwarded_element(), comma()) |> eof
  end

  defp forwarded_element do
    sep_by1(forwarded_pair(), char(";"))
  end

  defp forwarded_pair do
    pair = [token(), ignore(char("=")), value()]
    pipe(pair, &List.to_tuple/1)
  end

  defp value do
    either(token(), quoted_string())
  end

  # https://tools.ietf.org/html/rfc7230#section-3.2.6

  defp token do
    word_of(~r/[!#$%&'*+\-.^_`|~0-9a-zA-Z]/)
  end

  defp quoted_string do
    quoted(string_of(either(qdtext(), quoted_pair())))
  end

  defp quoted(parser) do
    between(char("\""), parser, char("\""))
  end

  defp string_of(parser) do
    map(many(parser), &Enum.join/1)
  end

  defp qdtext do
    word_of(~r/[\t \x21\x23-\x5B\x5D-\x7E\x80-\xFF]/)
  end

  @quotable ([?\t] ++
               Enum.to_list(0x21..0x7E) ++
               Enum.to_list(0x80..0xFF))
            |> Enum.map(&<<&1::utf8>>)

  defp quoted_pair do
    ignore(char("\\")) |> one_of(char(), @quotable)
  end

  # https://tools.ietf.org/html/rfc7230#section-7

  defp comma do
    skip(many(either(space(), tab())))
    |> char(",")
    |> skip(many(either(space(), tab())))
  end

  # https://tools.ietf.org/html/rfc7239#section-6

  defp ip_address do
    node_name()
    |> ignore(option(ignore(char(":")) |> node_port))
    |> eof
  end

  defp node_name do
    choice([
      ipv4_address(),
      between(char("["), ipv6_address(), char("]")),
      ignore(string("unknown")),
      ignore(obfuscated())
    ])
  end

  defp node_port(previous) do
    previous |> either(port(), obfuscated())
  end

  defp port do
    # Have to try to parse the wider integers first due to greediness. For
    # example, the port "12345" would be matched by fixed_integer(1) and the
    # remaining "2345" would cause a parse error for the eof in ip_address/0.

    choice(Enum.map(5..1, &fixed_integer/1))
  end

  defp obfuscated do
    word_of(~r/^_[a-zA-Z0-9._\-]+/)
  end

  # Could follow the ABNF described in
  # https://tools.ietf.org/html/rfc3986#section-3.2.2, but prefer to lean on
  # the existing :inet parser - we want its output anyway.

  defp ipv4_address do
    map(word_of(~r/[0-9.]/), fn string ->
      case :inet.parse_ipv4strict_address(string |> to_charlist) do
        {:ok, ip} -> ip
        {:error, :einval} -> {:error, "Invalid IPv4 address"}
      end
    end)
  end

  defp ipv6_address do
    map(word_of(~r/[0-9a-f:.]/i), fn string ->
      case :inet.parse_ipv6strict_address(string |> to_charlist) do
        {:ok, ip} -> ip
        {:error, :einval} -> {:error, "Invalid IPv6 address"}
      end
    end)
  end
end
