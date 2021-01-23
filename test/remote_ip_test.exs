defmodule RemoteIpTest do
  use ExUnit.Case, async: true
  use Plug.Test
  doctest RemoteIp

  @unknown [
    {"forwarded", "for=unknown"},
    {"x-forwarded-for", "not_an_ip"},
    {"x-client-ip", "_obf"},
    {"x-real-ip", "1.2.3"},
    {"custom", "::g"},
  ]

  @loopback [
    {"forwarded", "for=127.0.0.1"},
    {"x-forwarded-for", "::1"},
    {"x-client-ip", "127.0.0.2"},
    {"x-real-ip", "::::::1"},
    {"custom", "127.127.127.127"},
  ]

  @private [
    {"forwarded", "for=10.0.0.1"},
    {"x-forwarded-for", "172.16.0.1"},
    {"x-client-ip", "fd00::"},
    {"x-real-ip", "192.168.10.10"},
    {"custom", "172.31.41.59"},
  ]

  @public_v4 [
    {"forwarded", "for=2.71.82.8"},
    {"x-forwarded-for", "2.71.82.8"},
    {"x-client-ip", "2.71.82.8"},
    {"x-real-ip", "2.71.82.8"},
    {"custom", "2.71.82.8"},
  ]

  @public_v6 [
    {"forwarded", "for=\"[::2.71.82.8]\""},
    {"x-forwarded-for", "::247:5208"},
    {"x-client-ip", "0:0:0:0:0:0:2.71.82.8"},
    {"x-real-ip", "0::0:247:5208"},
    {"custom", "0:0::2.71.82.8"},
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
      assert Logger.metadata[:remote_ip] == "86.75.30.9"
    end

    for {header, value} <- @unknown do
      test "#{header} header from unknown IP" do
        peer = {1, 2, 3, 4}
        head = [{unquote(header), unquote(value)}]
        conn = %Plug.Conn{remote_ip: peer, req_headers: head}
        opts = [headers: [unquote(header)]]
        assert call(conn, opts).remote_ip == peer
        assert Logger.metadata[:remote_ip] == "1.2.3.4"
      end
    end

    for {header, value} <- @loopback do
      test "#{header} header from loopback IP" do
        peer = {0xd, 0xe, 0xa, 0xd, 0xb, 0xe, 0xe, 0xf}
        head = [{unquote(header), unquote(value)}]
        conn = %Plug.Conn{remote_ip: peer, req_headers: head}
        opts = [headers: [unquote(header)]]
        assert call(conn, opts).remote_ip == peer
        assert Logger.metadata[:remote_ip] == "d:e:a:d:b:e:e:f"
      end
    end

    for {header, value} <- @private do
      test "#{header} header from private IP" do
        peer = {0xde, 0xad, 0, 0, 0, 0, 0xbe, 0xef}
        head = [{unquote(header), unquote(value)}]
        conn = %Plug.Conn{remote_ip: peer, req_headers: head}
        opts = [headers: [unquote(header)]]
        assert call(conn, opts).remote_ip == peer
        assert Logger.metadata[:remote_ip] == "de:ad::be:ef"
      end
    end

    for {header, value} <- @public_v4 do
      test "#{header} header from public IP (v4)" do
        peer = {3, 141, 59, 27}
        head = [{unquote(header), unquote(value)}]
        conn = %Plug.Conn{remote_ip: peer, req_headers: head}
        opts = [headers: [unquote(header)]]
        assert call(conn, opts).remote_ip == {2, 71, 82, 8}
        assert Logger.metadata[:remote_ip] == "2.71.82.8"
      end
    end

    for {header, value} <- @public_v6 do
      test "#{header} header from public IP (v6)" do
        peer = {3, 141, 59, 27}
        head = [{unquote(header), unquote(value)}]
        conn = %Plug.Conn{remote_ip: peer, req_headers: head}
        opts = [headers: [unquote(header)]]
        assert call(conn, opts).remote_ip == {0, 0, 0, 0, 0, 0, 583, 21000}
        assert Logger.metadata[:remote_ip] == "::2.71.82.8"
      end
    end
  end

  describe "from/2" do
    test "no headers" do
      head = []
      assert RemoteIp.from(head) == nil
      assert Logger.metadata[:remote_ip] == nil
    end

    for {header, value} <- @unknown do
      test "#{header} header from unknown IP" do
        head = [{unquote(header), unquote(value)}]
        opts = [headers: [unquote(header)]]
        assert RemoteIp.from(head, opts) == nil
        assert Logger.metadata[:remote_ip] == nil
      end
    end

    for {header, value} <- @loopback do
      test "#{header} header from loopback IP" do
        head = [{unquote(header), unquote(value)}]
        opts = [headers: [unquote(header)]]
        assert RemoteIp.from(head, opts) == nil
        assert Logger.metadata[:remote_ip] == nil
      end
    end

    for {header, value} <- @private do
      test "#{header} header from private IP" do
        head = [{unquote(header), unquote(value)}]
        opts = [headers: [unquote(header)]]
        assert RemoteIp.from(head, opts) == nil
        assert Logger.metadata[:remote_ip] == nil
      end
    end

    for {header, value} <- @public_v4 do
      test "#{header} header from public IP (v4)" do
        head = [{unquote(header), unquote(value)}]
        opts = [headers: [unquote(header)]]
        assert RemoteIp.from(head, opts) == {2, 71, 82, 8}
        assert Logger.metadata[:remote_ip] == nil
      end
    end

    for {header, value} <- @public_v6 do
      test "#{header} header from public IP (v6)" do
        head = [{unquote(header), unquote(value)}]
        opts = [headers: [unquote(header)]]
        assert RemoteIp.from(head, opts) == {0, 0, 0, 0, 0, 0, 583, 21000}
        assert Logger.metadata[:remote_ip] == nil
      end
    end
  end

  @proxies [
    {"forwarded", "for=1.2.3.4"},
    {"x-forwarded-for", "::a"},
    {"x-client-ip", "1:2:3:4:5:6:7:8"},
    {"x-real-ip", "4.4.4.4"},
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
  end

  @clients [
    {"forwarded", "for=2.71.82.81"},
    {"x-forwarded-for", "82.84.59.0"},
    {"x-client-ip", "45.235.36.0"},
    {"x-real-ip", "28.74.71.35"},
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
        clients: ~w[2.71.0.0/16],
      ]
      assert RemoteIp.from(head, opts) == {2, 71, 82, 81}
    end

    test "doesn't impact presumed clients" do
      head = @clients
      opts = [clients: ~w[2.0.0.0/8 82.84.0.0/16 45.235.36.0/24 28.74.71.35/32]]
      assert RemoteIp.from(head, opts) == {28, 74, 71, 35}
    end
  end

  @headers [
    {"forwarded", "for=1.2.3.4"},
    {"x-forwarded-for", "1.2.3.4"},
    {"x-client-ip", "1.2.3.4"},
    {"x-real-ip", "1.2.3.4"},
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
end
