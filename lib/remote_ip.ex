defmodule RemoteIp do
  @behaviour Plug

  @headers ~w[
    forwarded
    x-forwarded-for
  ]
  # x-client-ip
  # x-real-ip
  # etc

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
    proxies = Keyword.get(opts, :proxies, @proxies) ++ @reserved
    proxies = proxies |> Enum.map(&InetCidr.parse/1)

    {headers, proxies}
  end

  def call(conn, {[], _proxies}) do
    conn
  end

  def call(conn, {[header | next_headers], proxies}) when is_binary(header) do
    case last_forwarded_ip(conn, header, proxies) do
      nil -> call(conn, {next_headers, proxies})
      ip  -> %{conn | remote_ip: ip}
    end
  end

  defp last_forwarded_ip(conn, header, proxies) do
    conn
    |> ips_from(header)
    |> last_ip_forwarded_through(proxies)
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

  defp ips_from(conn, "forwarded" = header) do
    conn
    |> Plug.Conn.get_req_header(header)
    |> RemoteIp.Headers.Forwarded.parse
  end

  defp ips_from(conn, header) when is_binary(header) do
    conn
    |> Plug.Conn.get_req_header(header)
    |> RemoteIp.Headers.Generic.parse
  end
end
