defmodule RemoteIpTest do
  use ExUnit.Case, async: true
  use Plug.Test

  def remote_ip(conn, opts \\ []) do
    RemoteIp.call(conn, RemoteIp.init(opts)).remote_ip
  end

  test "no forwarding headers" do
    assert nil == remote_ip(%Plug.Conn{})
  end

  describe "Forwarded" do
    test "from an unknown IP" do
      head = [{"forwarded", "for=unknown"}]
      conn = %Plug.Conn{req_headers: head}
      assert nil == remote_ip(conn)
    end

    test "from a loopback IP" do
      head = [{"forwarded", "for=127.0.0.1"}]
      conn = %Plug.Conn{req_headers: head}
      assert nil == remote_ip(conn)
    end

    test "from a private IP" do
      head = [{"forwarded", "for=10.0.0.1"}]
      conn = %Plug.Conn{req_headers: head}
      assert nil == remote_ip(conn)
    end

    test "from a public IP" do
      head = [{"forwarded", "for=1.2.3.4"}]
      conn = %Plug.Conn{req_headers: head}
      assert {1, 2, 3, 4} == remote_ip(conn)
    end

    test "from a known proxy" do
      head = [{"forwarded", "for=1.2.3.4"}]
      conn = %Plug.Conn{req_headers: head}
      opts = [proxies: ~w[1.2.0.0/16]]
      assert nil == remote_ip(conn, opts)
    end

    test "from a known client" do
      head = [{"forwarded", "for=1.2.3.4"}]
      conn = %Plug.Conn{req_headers: head}
      opts = [proxies: ~w[1.2.0.0/16], clients: ~w[1.2.3.4/32]]
      assert {1, 2, 3, 4} == remote_ip(conn, opts)
    end
  end

  describe "X-Forwarded-For" do
    test "from an unknown IP" do
      head = [{"x-forwarded-for", "not_an_ip"}]
      conn = %Plug.Conn{req_headers: head}
      assert nil == remote_ip(conn)
    end

    test "from a loopback IP" do
      head = [{"x-forwarded-for", "::1"}]
      conn = %Plug.Conn{req_headers: head}
      assert nil == remote_ip(conn)
    end

    test "from a private IP" do
      head = [{"x-forwarded-for", "172.16.0.1"}]
      conn = %Plug.Conn{req_headers: head}
      assert nil == remote_ip(conn)
    end

    test "from a public IP" do
      head = [{"x-forwarded-for", "4.5.6.7"}]
      conn = %Plug.Conn{req_headers: head}
      assert {4, 5, 6, 7} == remote_ip(conn)
    end

    test "from a known proxy" do
      head = [{"x-forwarded-for", "::a"}]
      conn = %Plug.Conn{req_headers: head}
      opts = [proxies: ~w[::a/128]]
      assert nil == remote_ip(conn, opts)
    end

    test "from a known client" do
      head = [{"x-forwarded-for", "::1:2:3:4"}]
      conn = %Plug.Conn{req_headers: head}
      opts = [proxies: ~w[::/64], clients: ~w[::1:2:0:0/96]]
      assert {0, 0, 0, 0, 1, 2, 3, 4} == remote_ip(conn, opts)
    end
  end

  describe "X-Client-IP" do
    test "from an unknown IP" do
      head = [{"x-client-ip", "_obf"}]
      conn = %Plug.Conn{req_headers: head}
      assert nil == remote_ip(conn)
    end

    test "from a loopback IP" do
      head = [{"x-client-ip", "127.0.0.2"}]
      conn = %Plug.Conn{req_headers: head}
      assert nil == remote_ip(conn)
    end

    test "from a private IP" do
      head = [{"x-client-ip", "fd00::"}]
      conn = %Plug.Conn{req_headers: head}
      assert nil == remote_ip(conn)
    end

    test "from a public IP" do
      head = [{"x-client-ip", "1:2:3:4:5:6:7:8"}]
      conn = %Plug.Conn{req_headers: head}
      assert {1, 2, 3, 4, 5, 6, 7, 8} == remote_ip(conn)
    end

    test "from a known proxy" do
      head = [{"x-client-ip", "1:2:3:4:5:6:7:8"}]
      conn = %Plug.Conn{req_headers: head}
      opts = [proxies: ~w[::/0]]
      assert nil == remote_ip(conn, opts)
    end

    test "from a known client" do
      head = [{"x-client-ip", "127.0.0.1"}]
      conn = %Plug.Conn{req_headers: head}
      opts = [clients: ~w[127.0.0.0/8]]
      assert {127, 0, 0, 1} == remote_ip(conn, opts)
    end
  end

  describe "X-Real-IP" do
    test "from an unknown IP" do
      head = [{"x-real-ip", "1.2.3"}]
      conn = %Plug.Conn{req_headers: head}
      assert nil == remote_ip(conn)
    end

    test "from a loopback IP" do
      head = [{"x-real-ip", "::::::1"}]
      conn = %Plug.Conn{req_headers: head}
      assert nil == remote_ip(conn)
    end

    test "from a private IP" do
      head = [{"x-real-ip", "192.168.10.10"}]
      conn = %Plug.Conn{req_headers: head}
      assert nil == remote_ip(conn)
    end

    test "from a public IP" do
      head = [{"x-real-ip", "8.9.10.11"}]
      conn = %Plug.Conn{req_headers: head}
      assert {8, 9, 10, 11} == remote_ip(conn)
    end

    test "from a known proxy" do
      head = [{"x-real-ip", "4.4.4.4"}]
      conn = %Plug.Conn{req_headers: head}
      opts = [proxies: ~w[0.0.0.0/0]]
      assert nil == remote_ip(conn, opts)
    end

    test "from a known client" do
      head = [{"x-real-ip", "10.45.90.135"}]
      conn = %Plug.Conn{req_headers: head}
      opts = [clients: ~w[10.45.0.0/16]]
      assert {10, 45, 90, 135} == remote_ip(conn, opts)
    end
  end

  describe "custom forwarding header" do
    test "from an unknown IP" do
      head = [{"custom", "::g"}]
      conn = %Plug.Conn{req_headers: head}
      opts = [headers: ~w[custom]]
      assert nil == remote_ip(conn, opts)
    end

    test "from a loopback IP" do
      head = [{"custom", "127.127.127.127"}]
      conn = %Plug.Conn{req_headers: head}
      opts = [headers: ~w[custom]]
      assert nil == remote_ip(conn, opts)
    end

    test "from a private IP" do
      head = [{"custom", "172.31.41.59"}]
      conn = %Plug.Conn{req_headers: head}
      opts = [headers: ~w[custom]]
      assert nil == remote_ip(conn, opts)
    end

    test "from a public IP" do
      head = [{"custom", "86.75.30.9"}]
      conn = %Plug.Conn{req_headers: head}
      opts = [headers: ~w[custom]]
      assert {86, 75, 30, 9} == remote_ip(conn, opts)
    end

    test "from a known proxy" do
      head = [{"custom", "8.8.8.8"}]
      conn = %Plug.Conn{req_headers: head}
      opts = [proxies: ~w[8.8.8.8/32], headers: ~w[custom]]
      assert nil == remote_ip(conn, opts)
    end

    test "from a known client" do
      head = [{"custom", "192.168.0.1"}]
      conn = %Plug.Conn{req_headers: head}
      opts = [clients: ~w[192.168.0.0/24], headers: ~w[custom]]
      assert {192, 168, 0, 1} == remote_ip(conn, opts)
    end
  end

  describe "multiple headers" do
    test "from unknown to unknown" do
      head = [{"forwarded", "for=unknown,for=_obf"}]
      conn = %Plug.Conn{req_headers: head}
      assert nil == remote_ip(conn)
    end

    test "from unknown to loopback" do
      head = [{"x-forwarded-for", "unknown,::1"}]
      conn = %Plug.Conn{req_headers: head}
      assert nil == remote_ip(conn)
    end

    test "from unknown to private" do
      head = [{"x-client-ip", "_obf, fc00:ABCD"}]
      conn = %Plug.Conn{req_headers: head}
      assert nil == remote_ip(conn)
    end

    test "from unknown to proxy" do
      head = [{"x-real-ip", "not_an_ip , 1.2.3.4"}]
      conn = %Plug.Conn{req_headers: head}
      opts = [proxies: ~w[1.0.0.0/12]]
      assert nil == remote_ip(conn, opts)
    end

    test "from unknown to client" do
      head = [{"custom", "unknown ,1.2.3.4"}]
      conn = %Plug.Conn{req_headers: head}
      opts = [headers: ~w[custom]]
      assert {1, 2, 3, 4} == remote_ip(conn, opts)
    end

    test "from loopback to unknown" do
      head = [{"forwarded", "for=\"[::1]\""}, {"x-forwarded-for", "_bogus"}]
      conn = %Plug.Conn{req_headers: head}
      assert nil == remote_ip(conn)
    end

    test "from loopback to loopback" do
      head = [{"x-client-ip", "127.0.0.1"}, {"x-real-ip", "127.0.0.1"}]
      conn = %Plug.Conn{req_headers: head}
      assert nil == remote_ip(conn)
    end

    test "from loopback to private" do
      head = [{"custom", "127.0.0.10"}, {"forwarded", "for=\"[fc00::1]\""}]
      conn = %Plug.Conn{req_headers: head}
      opts = [headers: ~w[forwarded custom]]
      assert nil == remote_ip(conn, opts)
    end

    test "from loopback to proxy" do
      head = [{"forwarded", "for=127.0.0.1"}, {"forwarded", "for=1.2.3.4"}]
      conn = %Plug.Conn{req_headers: head}
      opts = [proxies: ~w[1.2.3.4/32]]
      assert nil == remote_ip(conn, opts)
    end

    test "from loopback to client" do
      head = [{"x-forwarded-for", "127.0.0.1"}, {"x-forwarded-for", "1.2.3.4"}]
      conn = %Plug.Conn{req_headers: head}
      assert {1, 2, 3, 4} == remote_ip(conn)
    end

    test "from private to unknown" do
      head = [{"x-client-ip", "fc00::ABCD"}, {"x-client-ip", "_obf"}]
      conn = %Plug.Conn{req_headers: head}
      assert nil == remote_ip(conn)
    end

    test "from private to loopback" do
      head = [{"x-real-ip", "192.168.1.2"}, {"x-real-ip", "::1"}]
      conn = %Plug.Conn{req_headers: head}
      assert nil == remote_ip(conn)
    end

    test "from private to private" do
      head = [{"custom", "10.0.0.1"}, {"custom", "10.0.0.2"}]
      conn = %Plug.Conn{req_headers: head}
      opts = [headers: ~w[custom]]
      assert nil == remote_ip(conn, opts)
    end

    test "from private to proxy" do
      head = [{"forwarded", "for=10.0.10.0, for=\"[::1.2.3.4]\""}]
      conn = %Plug.Conn{req_headers: head}
      opts = [proxies: ~w[::/64]]
      assert nil == remote_ip(conn, opts)
    end

    test "from private to client" do
      head = [{"x-forwarded-for", "10.0.10.0, ::1.2.3.4"}]
      conn = %Plug.Conn{req_headers: head}
      opts = [proxies: ~w[255.0.0.0/8]]
      assert {0, 0, 0, 0, 0, 0, 258, 772} == remote_ip(conn, opts)
    end

    test "from proxy to unknown" do
      head = [{"x-client-ip", "a:b:c:d:e:f::,unknown"}]
      conn = %Plug.Conn{req_headers: head}
      opts = [proxies: ~w[::/0]]
      assert nil == remote_ip(conn, opts)
    end

    test "from proxy to loopback" do
      head = [
        {"x-real-ip", "2001:0db8:85a3:0000:0000:8A2E:0370:7334"},
        {"x-real-ip", "127.0.0.2"}
      ]
      conn = %Plug.Conn{req_headers: head}
      opts = [proxies: ~w[2001:0db8:85a3::8A2E:0370:7334/128]]
      assert nil == remote_ip(conn, opts)
    end

    test "from proxy to private" do
      head = [{"custom", "3.4.5.6 , 172.16.1.2"}]
      conn = %Plug.Conn{req_headers: head}
      opts = [headers: ~w[custom], proxies: ~w[3.0.0.0/8]]
      assert nil == remote_ip(conn, opts)
    end

    test "from proxy to proxy" do
      head = [{"forwarded", "for=1.2.3.4, for=1.2.3.5"}]
      conn = %Plug.Conn{req_headers: head}
      opts = [proxies: ~w[1.2.3.0/24]]
      assert nil == remote_ip(conn, opts)
    end

    test "from proxy to client" do
      head = [{"x-forwarded-for", "::1:2:3:4, ::3:4:5:6"}]
      conn = %Plug.Conn{req_headers: head}
      opts = [proxies: ~w[::1:2:3:4/128]]
      assert {0, 0, 0, 0, 3, 4, 5, 6} == remote_ip(conn, opts)
    end

    test "from client to unknown" do
      head = [{"x-client-ip", "a:b:c:d:e:f::,unknown"}]
      conn = %Plug.Conn{req_headers: head}
      opts = [proxies: ~w[b::/64]]
      assert {0xA, 0xB, 0xC, 0xD, 0xE, 0xF, 0x0, 0x0} == remote_ip(conn, opts)
    end

    test "from client to loopback" do
      head = [{"x-real-ip", "127.0.0.1"}, {"x-real-ip", "127.0.0.2"}]
      conn = %Plug.Conn{req_headers: head}
      opts = [clients: ~w[127.0.0.1/32]]
      assert {127, 0, 0, 1} == remote_ip(conn, opts)
    end

    test "from client to private" do
      head = [{"custom", "::1.2.3.4, 10.0.10.0"}]
      conn = %Plug.Conn{req_headers: head}
      opts = [proxies: ~w[1:2:3:4::/64], headers: ~w[custom]]
      assert {0, 0, 0, 0, 0, 0, 258, 772} == remote_ip(conn, opts)
    end

    test "from client to proxy" do
      head = [{"forwarded", "for=1.2.3.4,for=3.4.5.6"}]
      conn = %Plug.Conn{req_headers: head}
      opts = [proxies: ~w[3.4.5.0/24]]
      assert {1, 2, 3, 4} == remote_ip(conn, opts)
    end

    test "from client to client" do
      head = [{"x-forwarded-for", "1.2.3.4"}, {"x-forwarded-for", "10.45.0.1"}]
      conn = %Plug.Conn{req_headers: head}
      opts = [clients: ~w[10.45.0.0/16]]
      assert {10, 45, 0, 1} == remote_ip(conn, opts)
    end

    test "more than two hops" do
      head = [
        {"forwarded", "for=\"[fe80::0202:b3ff:fe1e:8329]\""},
        {"forwarded", "for=1.2.3.4"},
        {"x-forwarded-for", "172.16.0.10"},
        {"x-client-ip", "::1, ::1"},
        {"x-real-ip", "2.3.4.5, fc00::1, 2.4.6.8"}
      ]
      conn = %Plug.Conn{req_headers: head}
      opts = [proxies: ~w[2.0.0.0/8]]
      assert {1, 2, 3, 4} == remote_ip(conn, opts)
    end
  end

  describe ":headers option" do
    test "overrides the defaults" do
      head = [
        {"forwarded", "for=1.2.3.4"},
        {"x-forwarded-for", "1.2.3.4"},
        {"x-client-ip", "1.2.3.4"},
        {"x-real-ip", "1.2.3.4"}
      ]
      conn = %Plug.Conn{req_headers: head}
      opts = [headers: ~w[custom]]
      fail = "default headers are still being parsed"
      refute {1, 2, 3, 4} == remote_ip(conn, opts), fail
    end

    test "order doesn't matter" do
      head = [{"a", "1.2.3.4"}, {"b", "2.3.4.5"}, {"c", "3.4.5.6"}]
      conn = %Plug.Conn{req_headers: head}

      assert {3, 4, 5, 6} = remote_ip(conn, headers: ~w[a b c])
      assert {3, 4, 5, 6} = remote_ip(conn, headers: ~w[a c b])
      assert {3, 4, 5, 6} = remote_ip(conn, headers: ~w[b a c])
      assert {3, 4, 5, 6} = remote_ip(conn, headers: ~w[b c a])
      assert {3, 4, 5, 6} = remote_ip(conn, headers: ~w[c a b])
      assert {3, 4, 5, 6} = remote_ip(conn, headers: ~w[c b a])
    end

    test "ignores unspecified headers" do
      head = [{"a", "1.2.3.4"}, {"b", "2.3.4.5"}, {"c", "3.4.5.6"}]
      conn = %Plug.Conn{req_headers: head}

      assert {2, 3, 4, 5} = remote_ip(conn, headers: ~w[a b])
      assert {3, 4, 5, 6} = remote_ip(conn, headers: ~w[a c])
      assert {2, 3, 4, 5} = remote_ip(conn, headers: ~w[b a])
      assert {3, 4, 5, 6} = remote_ip(conn, headers: ~w[b c])
      assert {3, 4, 5, 6} = remote_ip(conn, headers: ~w[c a])
      assert {3, 4, 5, 6} = remote_ip(conn, headers: ~w[c b])
      assert {1, 2, 3, 4} = remote_ip(conn, headers: ~w[a])
      assert {2, 3, 4, 5} = remote_ip(conn, headers: ~w[b])
      assert {3, 4, 5, 6} = remote_ip(conn, headers: ~w[c])
    end
  end
end
