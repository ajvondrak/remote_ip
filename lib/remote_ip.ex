defmodule RemoteIp do
  @moduledoc """
  A plug to overwrite the `Plug.Conn`'s `remote_ip` based on headers such as
  `X-Forwarded-For`.

  To use, add the `RemoteIp` plug to your app's plug pipeline:

  ```elixir
  defmodule MyApp do
    use Plug.Builder

    plug RemoteIp
  end
  ```

  There are 2 options that can be passed in:

  * `:headers` - A list of strings naming the `req_headers` to use when
    deriving the `remote_ip`. Order does not matter. Defaults to `~w[forwarded
    x-forwarded-for x-client-ip x-real-ip]`.

  * `:proxies` - A list of strings in
    [CIDR](https://en.wikipedia.org/wiki/CIDR) notation specifying the IPs of
    known proxies. Defaults to `[]`.

  For example, if you know you are behind proxies in the IP block 1.2.x.x that
  use the `X-Foo`, `X-Bar`, and `X-Baz` headers, you could say

  ```elixir
  defmodule MyApp do
    use Plug.Builder

    plug RemoteIp, headers: ~w[x-foo x-bar x-baz], proxies: ~w[1.2.0.0/16]
  end
  ```

  Note that, due to limitations in the
  [inet_cidr](https://github.com/Cobenian/inet_cidr) library used to parse
  them, `:proxies` **must** be written in full CIDR notation, even if
  specifying just a single IP. So instead of `"127.0.0.1"` and `"a:b::c:d"`,
  you would use `"127.0.0.1/32"` and `"a:b::c:d/128"`.
  """

  @behaviour Plug

  @headers ~w[
    forwarded
    x-forwarded-for
    x-client-ip
    x-real-ip
  ]

  @proxies []

  # https://en.wikipedia.org/wiki/Loopback
  # https://en.wikipedia.org/wiki/Private_network
  @reserved ~w[
    127.0.0.0/8
    ::1/128
    fc00::/7
    10.0.0.0/8
    172.16.0.0/12
    192.168.0.0/16
  ]

  def init(opts \\ []) do
    headers = Keyword.get(opts, :headers, @headers)
    headers = MapSet.new(headers)
    proxies = Keyword.get(opts, :proxies, @proxies) ++ @reserved
    proxies = proxies |> Enum.map(&InetCidr.parse/1)

    {headers, proxies}
  end

  def call(conn, {headers, proxies}) do
    case last_forwarded_ip(conn, headers, proxies) do
      nil -> conn
      ip -> %{conn | remote_ip: ip}
    end
  end

  defp last_forwarded_ip(conn, headers, proxies) do
    conn
    |> ips_from(headers)
    |> last_ip_forwarded_through(proxies)
  end

  defp ips_from(%Plug.Conn{req_headers: headers}, allowed) do
    RemoteIp.Headers.parse(headers, allowed)
  end

  defp last_ip_forwarded_through(ips, proxies) do
    ips
    |> Enum.reverse()
    |> Enum.find(&forwarded?(&1, proxies))
  end

  defp forwarded?(ip, proxies) do
    !proxy?(ip, proxies)
  end

  defp proxy?(ip, proxies) do
    Enum.any?(proxies, fn proxy -> InetCidr.contains?(proxy, ip) end)
  end
end
