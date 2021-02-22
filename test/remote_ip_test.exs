defmodule RemoteIpTest do
  use ExUnit.Case, async: true
  use Plug.Test

  doctest RemoteIp

  @unknown [
    {"forwarded", "for=unknown"},
    {"x-forwarded-for", "not_an_ip"},
    {"x-client-ip", "_obf"},
    {"x-real-ip", "1.2.3"},
    {"custom", "::g"}
  ]

  @loopback [
    {"forwarded", "for=127.0.0.1"},
    {"x-forwarded-for", "::1"},
    {"x-client-ip", "127.0.0.2"},
    {"x-real-ip", "::::::1"},
    {"custom", "127.127.127.127"}
  ]

  @private [
    {"forwarded", "for=10.0.0.1"},
    {"x-forwarded-for", "172.16.0.1"},
    {"x-client-ip", "fd00::"},
    {"x-real-ip", "192.168.10.10"},
    {"custom", "172.31.41.59"}
  ]

  @public_v4 [
    {"forwarded", "for=2.71.82.8"},
    {"x-forwarded-for", "2.71.82.8"},
    {"x-client-ip", "2.71.82.8"},
    {"x-real-ip", "2.71.82.8"},
    {"custom", "2.71.82.8"}
  ]

  @public_v6 [
    {"forwarded", "for=\"[::2.71.82.8]\""},
    {"x-forwarded-for", "::247:5208"},
    {"x-client-ip", "0:0:0:0:0:0:2.71.82.8"},
    {"x-real-ip", "0::0:247:5208"},
    {"custom", "0:0::2.71.82.8"}
  ]

  def call(conn, opts \\ []) do
    RemoteIp.call(conn, RemoteIp.init(opts))
  end

  describe "call/2" do
    test "no headers" do
      peer = {86, 75, 30, 9}
      head = []
      conn = %Plug.Conn{remote_ip: peer, req_headers: head}
      assert call(conn).remote_ip == peer
      assert Logger.metadata()[:remote_ip] == "86.75.30.9"
    end

    for {header, value} <- @unknown do
      test "#{header} header from unknown IP" do
        peer = {1, 2, 3, 4}
        head = [{unquote(header), unquote(value)}]
        conn = %Plug.Conn{remote_ip: peer, req_headers: head}
        opts = [headers: [unquote(header)]]
        assert call(conn, opts).remote_ip == peer
        assert Logger.metadata()[:remote_ip] == "1.2.3.4"
      end
    end

    for {header, value} <- @loopback do
      test "#{header} header from loopback IP" do
        peer = {0xD, 0xE, 0xA, 0xD, 0xB, 0xE, 0xE, 0xF}
        head = [{unquote(header), unquote(value)}]
        conn = %Plug.Conn{remote_ip: peer, req_headers: head}
        opts = [headers: [unquote(header)]]
        assert call(conn, opts).remote_ip == peer
        assert Logger.metadata()[:remote_ip] == "d:e:a:d:b:e:e:f"
      end
    end

    for {header, value} <- @private do
      test "#{header} header from private IP" do
        peer = {0xDE, 0xAD, 0, 0, 0, 0, 0xBE, 0xEF}
        head = [{unquote(header), unquote(value)}]
        conn = %Plug.Conn{remote_ip: peer, req_headers: head}
        opts = [headers: [unquote(header)]]
        assert call(conn, opts).remote_ip == peer
        assert Logger.metadata()[:remote_ip] == "de:ad::be:ef"
      end
    end

    for {header, value} <- @public_v4 do
      test "#{header} header from public IP (v4)" do
        peer = {3, 141, 59, 27}
        head = [{unquote(header), unquote(value)}]
        conn = %Plug.Conn{remote_ip: peer, req_headers: head}
        opts = [headers: [unquote(header)]]
        assert call(conn, opts).remote_ip == {2, 71, 82, 8}
        assert Logger.metadata()[:remote_ip] == "2.71.82.8"
      end
    end

    for {header, value} <- @public_v6 do
      test "#{header} header from public IP (v6)" do
        peer = {3, 141, 59, 27}
        head = [{unquote(header), unquote(value)}]
        conn = %Plug.Conn{remote_ip: peer, req_headers: head}
        opts = [headers: [unquote(header)]]
        assert call(conn, opts).remote_ip == {0, 0, 0, 0, 0, 0, 583, 21000}
        assert Logger.metadata()[:remote_ip] == "::2.71.82.8"
      end
    end
  end

  describe "from/2" do
    test "no headers" do
      head = []
      assert RemoteIp.from(head) == nil
      assert Logger.metadata()[:remote_ip] == nil
    end

    for {header, value} <- @unknown do
      test "#{header} header from unknown IP" do
        head = [{unquote(header), unquote(value)}]
        opts = [headers: [unquote(header)]]
        assert RemoteIp.from(head, opts) == nil
        assert Logger.metadata()[:remote_ip] == nil
      end
    end

    for {header, value} <- @loopback do
      test "#{header} header from loopback IP" do
        head = [{unquote(header), unquote(value)}]
        opts = [headers: [unquote(header)]]
        assert RemoteIp.from(head, opts) == nil
        assert Logger.metadata()[:remote_ip] == nil
      end
    end

    for {header, value} <- @private do
      test "#{header} header from private IP" do
        head = [{unquote(header), unquote(value)}]
        opts = [headers: [unquote(header)]]
        assert RemoteIp.from(head, opts) == nil
        assert Logger.metadata()[:remote_ip] == nil
      end
    end

    for {header, value} <- @public_v4 do
      test "#{header} header from public IP (v4)" do
        head = [{unquote(header), unquote(value)}]
        opts = [headers: [unquote(header)]]
        assert RemoteIp.from(head, opts) == {2, 71, 82, 8}
        assert Logger.metadata()[:remote_ip] == nil
      end
    end

    for {header, value} <- @public_v6 do
      test "#{header} header from public IP (v6)" do
        head = [{unquote(header), unquote(value)}]
        opts = [headers: [unquote(header)]]
        assert RemoteIp.from(head, opts) == {0, 0, 0, 0, 0, 0, 583, 21000}
        assert Logger.metadata()[:remote_ip] == nil
      end
    end
  end

  @proxies [
    {"forwarded", "for=1.2.3.4"},
    {"x-forwarded-for", "::a"},
    {"x-client-ip", "1:2:3:4:5:6:7:8"},
    {"x-real-ip", "4.4.4.4"}
  ]

  describe ":proxies option" do
    test "can block presumed clients" do
      head = @proxies
      opts = [proxies: ~w[1.2.0.0/16 ::a/128 4.0.0.0/8 1::/30]]
      assert RemoteIp.from(head, opts) == nil
    end

    test "cannot block known clients" do
      head = @proxies
      opts = [proxies: ~w[0.0.0.0/0 ::/0], clients: ~w[1.2.0.0/16]]
      assert RemoteIp.from(head, opts) == {1, 2, 3, 4}
    end

    test "always includes reserved IPs" do
      head = @proxies ++ @loopback ++ @private
      opts = [proxies: ~w[1.2.0.0/16 ::a/128 4.0.0.0/8 1::/30 8.8.8.8/32]]
      assert RemoteIp.from(head, opts) == nil
    end

    test "can be an MFA" do
      head = [{"x-forwarded-for", "1.2.3.4, 2.3.4.5"}]
      opts = [proxies: {Application, :get_env, [:remote_ip_test, :proxies]}]

      Application.put_env(:remote_ip_test, :proxies, [])
      assert RemoteIp.from(head, opts) == {2, 3, 4, 5}

      Application.put_env(:remote_ip_test, :proxies, ~w[2.0.0.0/8])
      assert RemoteIp.from(head, opts) == {1, 2, 3, 4}
    end
  end

  @clients [
    {"forwarded", "for=2.71.82.81"},
    {"x-forwarded-for", "82.84.59.0"},
    {"x-client-ip", "45.235.36.0"},
    {"x-real-ip", "28.74.71.35"}
  ]

  describe ":clients option" do
    test "can allow reserved IPs" do
      head = @loopback ++ @private
      opts = [clients: ~w[192.168.10.0/24]]
      assert RemoteIp.from(head, opts) == {192, 168, 10, 10}
    end

    test "can allow known proxies" do
      head = @clients

      opts = [
        proxies: ~w[2.0.0.0/8 82.84.0.0/16 45.235.36.0/24 28.74.71.35/32],
        clients: ~w[2.71.0.0/16]
      ]

      assert RemoteIp.from(head, opts) == {2, 71, 82, 81}
    end

    test "doesn't impact presumed clients" do
      head = @clients
      opts = [clients: ~w[2.0.0.0/8 82.84.0.0/16 45.235.36.0/24 28.74.71.35/32]]
      assert RemoteIp.from(head, opts) == {28, 74, 71, 35}
    end

    test "can be an MFA" do
      head = [{"x-forwarded-for", "1.2.3.4, 127.0.0.1"}]
      opts = [clients: {Application, :get_env, [:remote_ip_test, :clients]}]

      Application.put_env(:remote_ip_test, :clients, [])
      assert RemoteIp.from(head, opts) == {1, 2, 3, 4}

      Application.put_env(:remote_ip_test, :clients, ~w[127.0.0.0/8])
      assert RemoteIp.from(head, opts) == {127, 0, 0, 1}
    end
  end

  @headers [
    {"forwarded", "for=1.2.3.4"},
    {"x-forwarded-for", "1.2.3.4"},
    {"x-client-ip", "1.2.3.4"},
    {"x-real-ip", "1.2.3.4"}
  ]

  describe ":headers option" do
    test "specifies which headers to use" do
      head = [{"a", "1.2.3.4"}, {"b", "2.3.4.5"}, {"c", "3.4.5.6"}]

      assert RemoteIp.from(head, headers: ~w[a b]) == {2, 3, 4, 5}
      assert RemoteIp.from(head, headers: ~w[a c]) == {3, 4, 5, 6}
      assert RemoteIp.from(head, headers: ~w[b a]) == {2, 3, 4, 5}
      assert RemoteIp.from(head, headers: ~w[b c]) == {3, 4, 5, 6}
      assert RemoteIp.from(head, headers: ~w[c a]) == {3, 4, 5, 6}
      assert RemoteIp.from(head, headers: ~w[c b]) == {3, 4, 5, 6}
      assert RemoteIp.from(head, headers: ~w[a]) == {1, 2, 3, 4}
      assert RemoteIp.from(head, headers: ~w[b]) == {2, 3, 4, 5}
      assert RemoteIp.from(head, headers: ~w[c]) == {3, 4, 5, 6}
    end

    for {header, value} <- @headers do
      test "includes #{header} by default" do
        head = [{unquote(header), unquote(value)}]
        assert RemoteIp.from(head) == {1, 2, 3, 4}
      end
    end

    test "overrides the defaults when specified" do
      head = @headers
      opts = [headers: ~w[custom]]
      fail = "default headers are still being parsed"
      refute RemoteIp.from(head, opts) == {1, 2, 3, 4}, fail
    end

    test "doesn't care about order" do
      head = [{"a", "1.2.3.4"}, {"b", "2.3.4.5"}, {"c", "3.4.5.6"}]

      assert RemoteIp.from(head, headers: ~w[a b c]) == {3, 4, 5, 6}
      assert RemoteIp.from(head, headers: ~w[a c b]) == {3, 4, 5, 6}
      assert RemoteIp.from(head, headers: ~w[b a c]) == {3, 4, 5, 6}
      assert RemoteIp.from(head, headers: ~w[b c a]) == {3, 4, 5, 6}
      assert RemoteIp.from(head, headers: ~w[c a b]) == {3, 4, 5, 6}
      assert RemoteIp.from(head, headers: ~w[c b a]) == {3, 4, 5, 6}
    end

    test "can be an MFA" do
      head = [{"a", "1.2.3.4"}, {"b", "2.3.4.5"}]
      opts = [headers: {Application, :get_env, [:remote_ip_test, :headers]}]

      Application.put_env(:remote_ip_test, :headers, ~w[a])
      assert RemoteIp.from(head, opts) == {1, 2, 3, 4}

      Application.put_env(:remote_ip_test, :headers, ~w[b])
      assert RemoteIp.from(head, opts) == {2, 3, 4, 5}
    end
  end

  describe "multiple headers" do
    test "from unknown to unknown" do
      head = [{"forwarded", "for=unknown,for=_obf"}]
      opts = []
      assert RemoteIp.from(head, opts) == nil
    end

    test "from unknown to loopback" do
      head = [{"x-forwarded-for", "unknown,::1"}]
      opts = []
      assert RemoteIp.from(head, opts) == nil
    end

    test "from unknown to private" do
      head = [{"x-client-ip", "_obf, fc00:ABCD"}]
      opts = []
      assert RemoteIp.from(head, opts) == nil
    end

    test "from unknown to proxy" do
      head = [{"x-real-ip", "not_an_ip , 1.2.3.4"}]
      opts = [proxies: ~w[1.0.0.0/12]]
      assert RemoteIp.from(head, opts) == nil
    end

    test "from unknown to client" do
      head = [{"custom", "unknown ,1.2.3.4"}]
      opts = [headers: ~w[custom]]
      assert RemoteIp.from(head, opts) == {1, 2, 3, 4}
    end

    test "from loopback to unknown" do
      head = [{"forwarded", "for=\"[::1]\""}, {"x-forwarded-for", "_bogus"}]
      opts = []
      assert RemoteIp.from(head, opts) == nil
    end

    test "from loopback to loopback" do
      head = [{"x-client-ip", "127.0.0.1"}, {"x-real-ip", "127.0.0.1"}]
      opts = []
      assert RemoteIp.from(head, opts) == nil
    end

    test "from loopback to private" do
      head = [{"custom", "127.0.0.10"}, {"forwarded", "for=\"[fc00::1]\""}]
      opts = [headers: ~w[forwarded custom]]
      assert RemoteIp.from(head, opts) == nil
    end

    test "from loopback to proxy" do
      head = [{"forwarded", "for=127.0.0.1"}, {"forwarded", "for=1.2.3.4"}]
      opts = [proxies: ~w[1.2.3.4/32]]
      assert RemoteIp.from(head, opts) == nil
    end

    test "from loopback to client" do
      head = [{"x-forwarded-for", "127.0.0.1"}, {"x-forwarded-for", "1.2.3.4"}]
      opts = []
      assert RemoteIp.from(head, opts) == {1, 2, 3, 4}
    end

    test "from private to unknown" do
      head = [{"x-client-ip", "fc00::ABCD"}, {"x-client-ip", "_obf"}]
      opts = []
      assert RemoteIp.from(head, opts) == nil
    end

    test "from private to loopback" do
      head = [{"x-real-ip", "192.168.1.2"}, {"x-real-ip", "::1"}]
      opts = []
      assert RemoteIp.from(head, opts) == nil
    end

    test "from private to private" do
      head = [{"custom", "10.0.0.1"}, {"custom", "10.0.0.2"}]
      opts = [headers: ~w[custom]]
      assert RemoteIp.from(head, opts) == nil
    end

    test "from private to proxy" do
      head = [{"forwarded", "for=10.0.10.0, for=\"[::1.2.3.4]\""}]
      opts = [proxies: ~w[::/64]]
      assert RemoteIp.from(head, opts) == nil
    end

    test "from private to client" do
      head = [{"x-forwarded-for", "10.0.10.0, ::1.2.3.4"}]
      opts = [proxies: ~w[255.0.0.0/8]]
      assert RemoteIp.from(head, opts) == {0, 0, 0, 0, 0, 0, 258, 772}
    end

    test "from proxy to unknown" do
      head = [{"x-client-ip", "a:b:c:d:e:f::,unknown"}]
      opts = [proxies: ~w[::/0]]
      assert RemoteIp.from(head, opts) == nil
    end

    test "from proxy to loopback" do
      head = [
        {"x-real-ip", "2001:0db8:85a3:0000:0000:8A2E:0370:7334"},
        {"x-real-ip", "127.0.0.2"}
      ]

      opts = [proxies: ~w[2001:0db8:85a3::8A2E:0370:7334/128]]
      assert RemoteIp.from(head, opts) == nil
    end

    test "from proxy to private" do
      head = [{"custom", "3.4.5.6 , 172.16.1.2"}]
      opts = [headers: ~w[custom], proxies: ~w[3.0.0.0/8]]
      assert RemoteIp.from(head, opts) == nil
    end

    test "from proxy to proxy" do
      head = [{"forwarded", "for=1.2.3.4, for=1.2.3.5"}]
      opts = [proxies: ~w[1.2.3.0/24]]
      assert RemoteIp.from(head, opts) == nil
    end

    test "from proxy to client" do
      head = [{"x-forwarded-for", "::1:2:3:4, ::3:4:5:6"}]
      opts = [proxies: ~w[::1:2:3:4/128]]
      assert RemoteIp.from(head, opts) == {0, 0, 0, 0, 3, 4, 5, 6}
    end

    test "from client to unknown" do
      head = [{"x-client-ip", "a:b:c:d:e:f::,unknown"}]
      opts = [proxies: ~w[b::/64]]
      assert RemoteIp.from(head, opts) == {10, 11, 12, 13, 14, 15, 0, 0}
    end

    test "from client to loopback" do
      head = [{"x-real-ip", "127.0.0.1"}, {"x-real-ip", "127.0.0.2"}]
      opts = [clients: ~w[127.0.0.1/32]]
      assert RemoteIp.from(head, opts) == {127, 0, 0, 1}
    end

    test "from client to private" do
      head = [{"custom", "::1.2.3.4, 10.0.10.0"}]
      opts = [proxies: ~w[1:2:3:4::/64], headers: ~w[custom]]
      assert RemoteIp.from(head, opts) == {0, 0, 0, 0, 0, 0, 258, 772}
    end

    test "from client to proxy" do
      head = [{"forwarded", "for=1.2.3.4,for=3.4.5.6"}]
      opts = [proxies: ~w[3.4.5.0/24]]
      assert RemoteIp.from(head, opts) == {1, 2, 3, 4}
    end

    test "from client to client" do
      head = [{"x-forwarded-for", "1.2.3.4"}, {"x-forwarded-for", "10.45.0.1"}]
      opts = [clients: ~w[10.45.0.0/16]]
      assert RemoteIp.from(head, opts) == {10, 45, 0, 1}
    end

    test "more than two hops" do
      head = [
        {"forwarded", "for=\"[fe80::0202:b3ff:fe1e:8329]\""},
        {"forwarded", "for=1.2.3.4"},
        {"x-forwarded-for", "172.16.0.10"},
        {"x-client-ip", "::1, ::1"},
        {"x-real-ip", "2.3.4.5, fc00::1, 2.4.6.8"}
      ]

      opts = [proxies: ~w[2.0.0.0/8]]
      assert RemoteIp.from(head, opts) == {1, 2, 3, 4}
    end
  end

  defmodule ParserA do
    @behaviour RemoteIp.Parser
    @impl RemoteIp.Parser
    def parse(value) do
      ips = RemoteIp.Parsers.Generic.parse(value)
      ips |> Enum.map(fn {a, b, c, d} -> {10 + a, 10 + b, 10 + c, 10 + d} end)
    end
  end

  defmodule ParserB do
    @behaviour RemoteIp.Parser
    @impl RemoteIp.Parser
    def parse(value) do
      ips = RemoteIp.Parsers.Generic.parse(value)
      ips |> Enum.map(fn {a, b, c, d} -> {20 + a, 20 + b, 20 + c, 20 + d} end)
    end
  end

  defmodule ParserC do
    @behaviour RemoteIp.Parser
    @impl RemoteIp.Parser
    def parse(value) do
      ips = RemoteIp.Parsers.Generic.parse(value)
      ips |> Enum.map(fn {a, b, c, d} -> {30 + a, 30 + b, 30 + c, 30 + d} end)
    end
  end

  describe ":parsers option" do
    test "can customize parsers for specific headers" do
      headers = [{"a", "1.2.3.4"}, {"b", "2.3.4.5"}, {"c", "3.4.5.6"}]
      parsers = %{"a" => ParserA, "b" => ParserB, "c" => ParserC}

      assert RemoteIp.from(headers, parsers: parsers, headers: ~w[a]) == {11, 12, 13, 14}
      assert RemoteIp.from(headers, parsers: parsers, headers: ~w[b]) == {22, 23, 24, 25}
      assert RemoteIp.from(headers, parsers: parsers, headers: ~w[c]) == {33, 34, 35, 36}
    end

    test "doesn't clobber generic parser on other headers" do
      headers = [{"a", "1.2.3.4"}, {"b", "2.3.4.5"}, {"c", "3.4.5.6"}]
      parsers = %{"a" => ParserA, "c" => ParserC}

      assert RemoteIp.from(headers, parsers: parsers, headers: ~w[a]) == {11, 12, 13, 14}
      assert RemoteIp.from(headers, parsers: parsers, headers: ~w[b]) == {2, 3, 4, 5}
      assert RemoteIp.from(headers, parsers: parsers, headers: ~w[c]) == {33, 34, 35, 36}
    end

    test "doesn't clobber Forwarded parser by default" do
      headers = [{"forwarded", "for=1.2.3.4"}]
      parsers = %{"a" => ParserA, "b" => ParserB, "c" => ParserC}
      options = [parsers: parsers, headers: ~w[forwarded a b c]]
      assert RemoteIp.from(headers, options) == {1, 2, 3, 4}
    end

    test "can clobber Forwarded parser" do
      headers = [{"forwarded", "1.2.3.4"}]
      parsers = %{"forwarded" => ParserA}
      options = [parsers: parsers, headers: ~w[forwarded]]
      assert RemoteIp.from(headers, options) == {11, 12, 13, 14}
    end

    test "can be an MFA" do
      headers = [{"x", "1.2.3.4"}]
      parsers = {Application, :get_env, [:remote_ip_test, :parsers]}
      options = [parsers: parsers, headers: ~w[x]]

      Application.put_env(:remote_ip_test, :parsers, %{"x" => ParserA})
      assert RemoteIp.from(headers, options) == {11, 12, 13, 14}

      Application.put_env(:remote_ip_test, :parsers, %{"x" => ParserC})
      assert RemoteIp.from(headers, options) == {31, 32, 33, 34}
    end
  end

  defmodule App do
    use Plug.Router

    plug RemoteIp,
      parsers: {__MODULE__, :parsers, []},
      headers: {__MODULE__, :config, ["HEADERS"]},
      proxies: {__MODULE__, :config, ["PROXIES"]},
      clients: {__MODULE__, :config, ["CLIENTS"]}

    plug :match
    plug :dispatch

    get "/ip" do
      send_resp(conn, 200, :inet.ntoa(conn.remote_ip))
    end

    def config(var) do
      System.get_env() |> Map.get(var, "") |> String.split(",", trim: true)
    end

    def parsers do
      Enum.into(config("PARSERS"), %{}, fn spec ->
        [header, parser] = String.split(spec, ":")
        {header, :"Elixir.RemoteIpTest.#{parser}"}
      end)
    end
  end

  test "runtime configuration" do
    try do
      conn = conn(:get, "/ip")
      conn = conn |> put_req_header("a", "1.2.3.4, 192.168.0.1, 2.3.4.5")
      conn = conn |> put_req_header("b", "3.4.5.6, 192.168.0.1, 4.5.6.7")

      assert App.call(conn, App.init([])).resp_body == "127.0.0.1"

      System.put_env("HEADERS", "a")
      assert App.call(conn, App.init([])).resp_body == "2.3.4.5"

      System.put_env("PARSERS", "a:ParserA")
      assert App.call(conn, App.init([])).resp_body == "12.13.14.15"

      System.put_env("PARSERS", "a:ParserB,c:ParserC")
      assert App.call(conn, App.init([])).resp_body == "22.23.24.25"

      System.put_env("PROXIES", "22.0.0.0/8,212.188.0.0/16")
      assert App.call(conn, App.init([])).resp_body == "21.22.23.24"

      System.delete_env("PARSERS")

      System.put_env("PROXIES", "2.1.0.0/16,2.2.0.0/16,2.3.0.0/16")
      assert App.call(conn, App.init([])).resp_body == "1.2.3.4"

      System.put_env("CLIENTS", "192.0.0.0/8,1.2.3.4/32")
      assert App.call(conn, App.init([])).resp_body == "192.168.0.1"

      System.put_env("HEADERS", "b,c,d")
      assert App.call(conn, App.init([])).resp_body == "4.5.6.7"

      System.put_env("PROXIES", "4.5.6.0/24")
      assert App.call(conn, App.init([])).resp_body == "192.168.0.1"

      System.put_env("CLIENTS", "4.5.7.0/24")
      assert App.call(conn, App.init([])).resp_body == "3.4.5.6"
    after
      System.delete_env("PARSERS")
      System.delete_env("HEADERS")
      System.delete_env("PROXIES")
      System.delete_env("CLIENTS")
    end
  end
end
