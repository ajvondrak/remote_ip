defmodule RemoteIp do
  @moduledoc """
  A plug to overwrite the `Plug.Conn`'s `remote_ip` based on request headers.

  To use, add the `RemoteIp` plug to your app's plug pipeline:

  ```elixir
  defmodule MyApp do
    use Plug.Builder

    plug RemoteIp
  end
  ```

  Keep in mind the order of plugs in your pipeline and place `RemoteIp` as
  early as possible. For example, if you were to add `RemoteIp` *after* [the
  Plug Router](https://github.com/elixir-lang/plug#the-plug-router), your route
  action's logic would be executed *before* the `remote_ip` actually gets
  modified - not very useful!

  There are 3 options that can be passed in:

  * `:headers` - A list of strings naming the `req_headers` to use when
    deriving the `remote_ip`. Order does not matter. Defaults to `~w[forwarded
    x-forwarded-for x-client-ip x-real-ip]`.

  * `:proxies` - A list of strings in
    [CIDR](https://en.wikipedia.org/wiki/CIDR) notation specifying the IPs of
    known proxies. Defaults to `[]`.

      [Loopback](https://en.wikipedia.org/wiki/Loopback) and
      [private](https://en.wikipedia.org/wiki/Private_network) IPs are always
      appended to this list:

      * 127.0.0.0/8
      * ::1/128
      * fc00::/7
      * 10.0.0.0/8
      * 172.16.0.0/12
      * 192.168.0.0/16

      Since these IPs are internal, they often are not the actual client
      address in production, so we add them by default. To override this
      behavior, whitelist known client IPs using the `:clients` option.

  * `:clients` - A list of strings in
    [CIDR](https://en.wikipedia.org/wiki/CIDR) notation specifying the IPs of
    known clients. Defaults to `[]`.

      An IP in any of the ranges listed here will never be considered a proxy.
      This takes precedence over the `:proxies` option, including
      loopback/private addresses. Any IP that is **not** covered by `:clients`
      or `:proxies` is assumed to be a client IP.

  For example, suppose you know:
  * you are behind proxies in the 1.2.x.x block
  * the proxies use the `X-Foo`, `X-Bar`, and `X-Baz` headers
  * but the IP 1.2.3.4 is actually a client, not one of the proxies

  Then you could say

  ```elixir
  defmodule MyApp do
    use Plug.Builder

    plug RemoteIp,
         headers: ~w[x-foo x-bar x-baz],
         proxies: ~w[1.2.0.0/16],
         clients: ~w[1.2.3.4/32]
  end
  ```

  Note that, due to limitations in the
  [inet_cidr](https://github.com/Cobenian/inet_cidr) library used to parse
  them, `:proxies` and `:clients` **must** be written in full CIDR notation,
  even if specifying just a single IP. So instead of `"127.0.0.1"` and
  `"a:b::c:d"`, you would use `"127.0.0.1/32"` and `"a:b::c:d/128"`.

  For more details, refer to the
  [README](https://github.com/ajvondrak/remote_ip/blob/master/README.md) on
  GitHub.
  """

  @behaviour Plug

  @headers ~w[
    forwarded
    x-forwarded-for
    x-client-ip
    x-real-ip
  ]

  @proxies []

  @clients []

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

    clients = Keyword.get(opts, :clients, @clients)
    clients = clients |> Enum.map(&InetCidr.parse/1)

    {headers, proxies, clients}
  end

  def call(conn, {headers, proxies, clients}) do
    case last_forwarded_ip(conn, headers, proxies, clients) do
      nil -> conn
      ip  -> %{conn | remote_ip: ip}
    end
  end

  defp last_forwarded_ip(conn, headers, proxies, clients) do
    conn
    |> ips_from(headers)
    |> last_ip_forwarded_through(proxies, clients)
  end

  defp ips_from(%Plug.Conn{req_headers: headers}, allowed) do
    RemoteIp.Headers.parse(headers, allowed)
  end

  defp last_ip_forwarded_through(ips, proxies, clients) do
    ips
    |> Enum.reverse
    |> Enum.find(&forwarded?(&1, proxies, clients))
  end

  defp forwarded?(ip, proxies, clients) do
    client?(ip, clients) || !proxy?(ip, proxies)
  end

  defp client?(ip, clients) do
    Enum.any?(clients, fn client -> InetCidr.contains?(client, ip) end)
  end

  defp proxy?(ip, proxies) do
    Enum.any?(proxies, fn proxy -> InetCidr.contains?(proxy, ip) end)
  end
end
