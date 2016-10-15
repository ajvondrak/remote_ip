defmodule RemoteIp do
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
      ip  -> %{conn | remote_ip: ip}
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
    |> Enum.reverse
    |> Enum.find(&forwarded?(&1, proxies))
  end

  defp forwarded?(ip, proxies) do
    !proxy?(ip, proxies)
  end

  defp proxy?(ip, proxies) do
    Enum.any?(proxies, fn proxy -> InetCidr.contains?(proxy, ip) end)
  end
end
