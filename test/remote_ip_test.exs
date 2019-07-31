defmodule RemoteIpTest do
  use ExUnit.Case, async: true
  use Plug.Test

  # put_req_header/3 will obliterate existing values, whereas we want to
  # append multiple values for the same header.
  #
  def add_req_header(%Plug.Conn{req_headers: headers} = conn, header, value) do
    %{conn | req_headers: headers ++ [{header, value}]}
  end

  def forwarded(conn, value), do: add_req_header(conn, "forwarded", value)
  def x_forwarded_for(conn, ip), do: add_req_header(conn, "x-forwarded-for", ip)
  def x_client_ip(conn, ip), do: add_req_header(conn, "x-client-ip", ip)
  def x_real_ip(conn, ip), do: add_req_header(conn, "x-real-ip", ip)
  def custom(conn, ip), do: add_req_header(conn, "custom", ip)

  def remote_ip(conn, opts \\ []) do
    RemoteIp.call(conn, RemoteIp.init(opts)).remote_ip
  end

  # Not a real IP address, but RemoteIp shouldn't ever be actually manipulating
  # this value. So, in this Conn, we use :peer as a canary in the coalmine.
  #
  @conn %Plug.Conn{remote_ip: :peer}

  test "zero hops (i.e., no forwarding headers)" do
    assert :peer == @conn |> remote_ip
    assert :peer == @conn |> remote_ip(headers: ~w[])
    assert :peer == @conn |> remote_ip(headers: ~w[custom])
    assert :peer == @conn |> remote_ip(proxies: ~w[])
    assert :peer == @conn |> remote_ip(proxies: ~w[0.0.0.0/0 ::/0])
    assert :peer == @conn |> remote_ip(headers: ~w[], proxies: ~w[])
    assert :peer == @conn |> remote_ip(headers: ~w[], proxies: ~w[0.0.0.0/0 ::/0])
    assert :peer == @conn |> remote_ip(headers: ~w[custom], proxies: ~w[])
    assert :peer == @conn |> remote_ip(headers: ~w[custom], proxies: ~w[0.0.0.0/0 ::/0])
  end

  describe "one hop" do
    test "from an unknown IP" do
      assert :peer == @conn |> forwarded("for=unknown") |> remote_ip
      assert :peer == @conn |> x_forwarded_for("not_an_ip") |> remote_ip
      assert :peer == @conn |> custom("_obf") |> remote_ip(headers: ~w[custom])
    end

    test "from a loopback IP" do
      assert :peer == @conn |> forwarded("for=127.0.0.1") |> remote_ip
      assert :peer == @conn |> x_client_ip("::1") |> remote_ip
      assert :peer == @conn |> custom("127.0.0.2") |> remote_ip(headers: ~w[custom])
    end

    test "from a private IP" do
      assert :peer == @conn |> forwarded("for=10.0.0.1") |> remote_ip
      assert :peer == @conn |> x_real_ip("172.16.0.1") |> remote_ip
      assert :peer == @conn |> x_forwarded_for("fd00::") |> remote_ip
      assert :peer == @conn |> custom("192.168.0.1") |> remote_ip(headers: ~w[custom])
    end

    test "from a public IP configured as a known proxy" do
      assert :peer == @conn |> forwarded("for=1.2.3.4") |> remote_ip(proxies: ~w[1.2.3.4/32])
      assert :peer == @conn |> x_client_ip("::a") |> remote_ip(proxies: ~w[::a/128])

      assert :peer ==
               @conn
               |> custom("1.2.3.4")
               |> remote_ip(headers: ~w[custom], proxies: ~w[1.2.0.0/16])
    end

    test "from a public IP not configured as a known proxy" do
      assert {1, 2, 3, 4} == @conn |> forwarded("for=1.2.3.4") |> remote_ip(proxies: ~w[::/0])

      assert {1, 2, 3, 4, 5, 6, 7, 8} ==
               @conn |> x_real_ip("1:2:3:4:5:6:7:8") |> remote_ip(proxies: ~w[1:1::/64])

      assert {1, 2, 3, 4} == @conn |> custom("1.2.3.4") |> remote_ip(headers: ~w[custom])
    end
  end

  describe "two hops" do
    test "from unknown to unknown" do
      assert :peer == @conn |> forwarded("for=unknown,for=_obf") |> remote_ip
      assert :peer == @conn |> x_forwarded_for("_obf,not_an_ip") |> remote_ip
      assert :peer == @conn |> custom("unknown,unknown") |> remote_ip(headers: ~w[custom])
    end

    test "from unknown to loopback" do
      assert :peer == @conn |> forwarded("for=_obf,for=127.0.0.1") |> remote_ip
      assert :peer == @conn |> x_client_ip("unknown,::1") |> remote_ip
      assert :peer == @conn |> custom("not_an_ip, 127.0.0.2") |> remote_ip(headers: ~w[custom])
    end

    test "from unknown to private" do
      assert :peer == @conn |> forwarded("for=unknown,for=10.10.10.10") |> remote_ip
      assert :peer == @conn |> x_real_ip("_obf, fc00::ABCD") |> remote_ip
      assert :peer == @conn |> x_forwarded_for("not_an_ip,192.168.0.4") |> remote_ip
      assert :peer == @conn |> custom("unknown,172.16.72.1") |> remote_ip(headers: ~w[custom])
    end

    test "from unknown to proxy" do
      assert :peer ==
               @conn |> forwarded("for=_obf,for=1.2.3.4") |> remote_ip(proxies: ~w[1.2.3.4/32])

      assert :peer ==
               @conn |> x_client_ip("unknown,a:b:c:d:e:f::") |> remote_ip(proxies: ~w[::/0])

      assert :peer ==
               @conn
               |> custom("not_an_ip,1.2.3.4")
               |> remote_ip(headers: ~w[custom], proxies: ~w[1.0.0.0/8])
    end

    test "from unknown to non-proxy" do
      assert {1, 2, 3, 4} ==
               @conn |> forwarded("for=unknown,for=1.2.3.4") |> remote_ip(proxies: ~w[1.2.3.5/32])

      assert {0xA, 0xB, 0xC, 0xD, 0xE, 0xF, 0x0, 0x0} ==
               @conn |> x_real_ip("_obf,a:b:c:d:e:f::") |> remote_ip

      assert {1, 2, 3, 4} ==
               @conn
               |> custom("not_an_ip,1.2.3.4")
               |> remote_ip(headers: ~w[custom], proxies: ~w[8.6.7.5/32 3:0:9::/64])
    end

    test "from loopback to unknown" do
      assert :peer == @conn |> forwarded("for=\"[::1]\",for=unknown") |> remote_ip
      assert :peer == @conn |> x_forwarded_for("127.0.0.1,not_an_ip") |> remote_ip

      assert :peer ==
               @conn |> custom("127.0.0.2,_obfuscated_ipaddr") |> remote_ip(headers: ~w[custom])
    end

    test "from loopback to loopback" do
      assert :peer == @conn |> forwarded("for=127.0.0.1, for=127.0.0.1") |> remote_ip
      assert :peer == @conn |> x_client_ip("::1, ::1") |> remote_ip
      assert :peer == @conn |> custom("::1, 127.0.0.1") |> remote_ip(headers: ~w[custom])
    end

    test "from loopback to private" do
      assert :peer == @conn |> forwarded("for=127.0.0.10, for=\"[fc00::1]\"") |> remote_ip
      assert :peer == @conn |> x_real_ip("::1, 192.168.1.2") |> remote_ip
      assert :peer == @conn |> custom("127.0.0.1, 172.16.0.1") |> remote_ip(headers: ~w[custom])
      assert :peer == @conn |> custom("127.1.2.3, 10.10.10.1") |> remote_ip(headers: ~w[custom])
    end

    test "from loopback to proxy" do
      assert :peer ==
               @conn
               |> forwarded("for=127.0.0.1 , for=1.2.3.4")
               |> remote_ip(proxies: ~w[1.2.3.4/32])

      assert :peer ==
               @conn |> x_forwarded_for("::1, 1.2.3.4") |> remote_ip(proxies: ~w[1.2.3.0/24])

      assert :peer ==
               @conn
               |> custom("127.0.0.2, 2001:0db8:85a3:0000:0000:8A2E:0370:7334")
               |> remote_ip(headers: ~w[custom], proxies: ~w[2001:0db8:85a3::8A2E:0370:7334/128])
    end

    test "from loopback to non-proxy" do
      assert {1, 2, 3, 4} == @conn |> forwarded("for=127.0.0.1, for=1.2.3.4") |> remote_ip

      assert {1, 2, 3, 4} ==
               @conn |> x_client_ip("::1, 1.2.3.4") |> remote_ip(proxies: ~w[2.0.0.0/8])

      assert {0x2001, 0x0DB8, 0x85A3, 0x0000, 0x0000, 0x8A2E, 0x0370, 0x7334} ==
               @conn
               |> custom("::1, 2001:0db8:85a3:0000:0000:8A2E:0370:7334")
               |> remote_ip(
                 headers: ~w[custom],
                 proxies: ~w[fe80:0000:0000:0000:0202:b3ff:fe1e:8329/128]
               )
    end

    test "from private to unknown" do
      assert :peer == @conn |> forwarded("for=10.10.10.10,for=unknown") |> remote_ip
      assert :peer == @conn |> x_forwarded_for("fc00::ABCD, _obf") |> remote_ip
      assert :peer == @conn |> x_real_ip("192.168.0.4, not_an_ip") |> remote_ip
      assert :peer == @conn |> custom("172.16.72.1, unknown") |> remote_ip(headers: ~w[custom])
    end

    test "from private to loopback" do
      assert :peer == @conn |> forwarded("for=\"[fc00::1]\", for=127.0.0.10") |> remote_ip
      assert :peer == @conn |> forwarded("for=10.10.10.1, for=127.1.2.3") |> remote_ip
      assert :peer == @conn |> x_client_ip("192.168.1.2, ::1") |> remote_ip
      assert :peer == @conn |> custom("172.16.0.1, 127.0.0.1") |> remote_ip(headers: ~w[custom])
    end

    test "from private to private" do
      assert :peer == @conn |> forwarded("for=172.16.0.1, for=\"[fc00::1]\"") |> remote_ip
      assert :peer == @conn |> x_real_ip("192.168.0.1, 192.168.0.2") |> remote_ip
      assert :peer == @conn |> custom("10.0.0.1, 10.0.0.2") |> remote_ip(headers: ~w[custom])
    end

    test "from private to proxy" do
      assert :peer ==
               @conn
               |> forwarded("for=\"[fc00::1:2:3]\", for=1.2.3.4")
               |> remote_ip(proxies: ~w[0.0.0.0/0])

      assert :peer ==
               @conn
               |> forwarded("for=10.0.10.0, for=\"[::1.2.3.4]\"")
               |> remote_ip(proxies: ~w[::/64])

      assert :peer ==
               @conn
               |> x_forwarded_for("192.168.0.1,1.2.3.4")
               |> remote_ip(proxies: ~w[1.2.0.0/16])

      assert :peer ==
               @conn
               |> custom("172.16.1.2, 3.4.5.6")
               |> remote_ip(headers: ~w[custom], proxies: ~w[3.0.0.0/8])
    end

    test "from private to non-proxy" do
      assert {1, 2, 3, 4} == @conn |> forwarded("for=\"[fc00::1:2:3]\", for=1.2.3.4") |> remote_ip

      assert {0, 0, 0, 0, 0, 0, 258, 772} ==
               @conn
               |> forwarded("for=10.0.10.0, for=\"[::1.2.3.4]\"")
               |> remote_ip(proxies: ~w[255.0.0.0/8])

      assert {1, 2, 3, 4} == @conn |> x_client_ip("192.168.0.1,1.2.3.4") |> remote_ip

      assert {3, 4, 5, 6} ==
               @conn
               |> custom("172.16.1.2 , 3.4.5.6")
               |> remote_ip(headers: ~w[custom], proxies: ~w[1.2.3.4/32])
    end

    test "from proxy to unknown" do
      assert :peer ==
               @conn |> forwarded("for=1.2.3.4,for=_obf") |> remote_ip(proxies: ~w[1.2.3.4/32])

      assert :peer == @conn |> x_real_ip("a:b:c:d:e:f::,unknown") |> remote_ip(proxies: ~w[::/0])

      assert :peer ==
               @conn
               |> custom("1.2.3.4,not_an_ip")
               |> remote_ip(headers: ~w[custom], proxies: ~w[1.0.0.0/8])
    end

    test "from proxy to loopback" do
      assert :peer ==
               @conn
               |> forwarded("for=1.2.3.4, for=127.0.0.1")
               |> remote_ip(proxies: ~w[1.2.3.4/32])

      assert :peer ==
               @conn |> x_forwarded_for("1.2.3.4, ::1") |> remote_ip(proxies: ~w[1.2.3.0/24])

      assert :peer ==
               @conn
               |> custom("2001:0db8:85a3:0000:0000:8A2E:0370:7334, 127.0.0.2")
               |> remote_ip(headers: ~w[custom], proxies: ~w[2001:0db8:85a3::8A2E:0370:7334/128])
    end

    test "from proxy to private" do
      assert :peer ==
               @conn
               |> forwarded("for=1.2.3.4, for=\"[fc00::1:2:3]\"")
               |> remote_ip(proxies: ~w[0.0.0.0/0])

      assert :peer ==
               @conn
               |> forwarded("for=\"[::1.2.3.4]\", for=10.0.10.0")
               |> remote_ip(proxies: ~w[::/64])

      assert :peer ==
               @conn |> x_client_ip("1.2.3.4,192.168.0.1") |> remote_ip(proxies: ~w[1.2.0.0/16])

      assert :peer ==
               @conn
               |> custom("3.4.5.6 , 172.16.1.2")
               |> remote_ip(headers: ~w[custom], proxies: ~w[3.0.0.0/8])
    end

    test "from proxy to proxy" do
      assert :peer ==
               @conn
               |> forwarded("for=1.2.3.4, for=1.2.3.5")
               |> remote_ip(proxies: ~w[1.2.3.0/24])

      assert :peer ==
               @conn
               |> x_real_ip("a:b:c:d::,1:2:3:4::")
               |> remote_ip(proxies: ~w[a:b:c:d::/128 1:2:3:4::/64])

      assert :peer ==
               @conn
               |> custom("1.2.3.4, 3.4.5.6")
               |> remote_ip(headers: ~w[custom], proxies: ~w[1.2.3.4/32 3.4.5.6/32])
    end

    test "from proxy to non-proxy" do
      assert {3, 4, 5, 6} ==
               @conn |> forwarded("for=1.2.3.4,for=3.4.5.6") |> remote_ip(proxies: ~w[1.2.3.4/32])

      assert {0, 0, 0, 0, 3, 4, 5, 6} ==
               @conn
               |> x_forwarded_for("::1:2:3:4, ::3:4:5:6")
               |> remote_ip(proxies: ~w[::1:2:3:4/128])

      assert {3, 4, 5, 6} ==
               @conn
               |> custom("1.2.3.4, 3.4.5.6")
               |> remote_ip(headers: ~w[custom], proxies: ~w[1.2.3.4/32])
    end

    test "from non-proxy to unknown" do
      assert {1, 2, 3, 4} == @conn |> forwarded("for=1.2.3.4,for=not_an_ip") |> remote_ip

      assert {0xA, 0xB, 0xC, 0xD, 0xE, 0xF, 0x0, 0x0} ==
               @conn |> x_client_ip("a:b:c:d:e:f::,unknown") |> remote_ip(proxies: ~w[b::/64])

      assert {1, 2, 3, 4} == @conn |> custom("1.2.3.4,_obf") |> remote_ip(headers: ~w[custom])
    end

    test "from non-proxy to loopback" do
      assert {1, 2, 3, 4} ==
               @conn
               |> forwarded("for=1.2.3.4, for=127.0.0.1")
               |> remote_ip(proxies: ~w[abcd::/32])

      assert {1, 2, 3, 4} ==
               @conn |> x_real_ip("1.2.3.4, ::1") |> remote_ip(proxies: ~w[4.3.2.1/32])

      assert {0x2001, 0x0DB8, 0x85A3, 0x0000, 0x0000, 0x8A2E, 0x0370, 0x7334} ==
               @conn
               |> custom("2001:0db8:85a3:0000:0000:8A2E:0370:7334, 127.0.0.2")
               |> remote_ip(headers: ~w[custom])
    end

    test "from non-proxy to private" do
      assert {1, 2, 3, 4} == @conn |> forwarded("for=1.2.3.4, for=\"[fc00::1:2:3]\"") |> remote_ip

      assert {0, 0, 0, 0, 0, 0, 258, 772} ==
               @conn
               |> forwarded("for=\"[::1.2.3.4]\", for=10.0.10.0")
               |> remote_ip(proxies: ~w[1:2:3:4::/64])

      assert {1, 2, 3, 4} ==
               @conn
               |> x_forwarded_for("1.2.3.4,192.168.0.1")
               |> remote_ip(proxies: ~w[1.2.3.5/32])

      assert {3, 4, 5, 6} ==
               @conn |> custom("3.4.5.6 , 172.16.1.2") |> remote_ip(headers: ~w[custom])
    end

    test "from non-proxy to proxy" do
      assert {1, 2, 3, 4} ==
               @conn |> forwarded("for=1.2.3.4,for=3.4.5.6") |> remote_ip(proxies: ~w[3.4.5.6/32])

      assert {0, 0, 0, 0, 1, 2, 3, 4} ==
               @conn
               |> x_client_ip("::1:2:3:4, ::3:4:5:6")
               |> remote_ip(proxies: ~w[::3:4:5:6/128])

      assert {1, 2, 3, 4} ==
               @conn
               |> custom("1.2.3.4, 3.4.5.6")
               |> remote_ip(headers: ~w[custom], proxies: ~w[3.4.5.0/24])
    end

    test "from non-proxy to non-proxy" do
      assert {3, 4, 5, 6} == @conn |> forwarded("for=1.2.3.4,for=3.4.5.6") |> remote_ip
      assert {0, 0, 0, 0, 3, 4, 5, 6} == @conn |> x_real_ip("::1:2:3:4, ::3:4:5:6") |> remote_ip

      assert {3, 4, 5, 6} ==
               @conn
               |> custom("1.2.3.4, 3.4.5.6")
               |> remote_ip(headers: ~w[custom], proxies: ~w[5.6.7.8/32])
    end
  end

  test "several hops" do
    conn =
      @conn
      |> forwarded("for=3.4.5.6")
      |> forwarded("for=10.0.0.1")
      |> forwarded("for=192.168.0.1")

    assert {3, 4, 5, 6} == conn |> remote_ip

    conn = @conn |> x_real_ip("9.9.9.9, 172.31.4.4, 3.4.5.6, 10.0.0.1")
    assert {3, 4, 5, 6} == conn |> remote_ip

    conn = @conn |> custom("fe80::0202:b3ff:fe1e:8329") |> custom("::1") |> custom("::1")

    assert {0xFE80, 0x0000, 0x0000, 0x0000, 0x0202, 0xB3FF, 0xFE1E, 0x8329} ==
             conn |> remote_ip(headers: ~w[custom])

    conn =
      @conn
      |> x_forwarded_for("2001:0db8:85a3::8a2e:0370:7334")
      |> x_forwarded_for("fe80:0000:0000:0000:0202:b3ff:fe1e:8329, ::1")
      |> x_forwarded_for("unknown, fc00::, fe00::, fdff::")

    assert {0xFE80, 0x0000, 0x0000, 0x0000, 0x0202, 0xB3FF, 0xFE1E, 0x8329} ==
             conn |> remote_ip(proxies: ~w[fe00::/128])
  end

  test "allowed headers" do
    conn =
      @conn
      |> put_req_header("a", "1.2.3.4")
      |> put_req_header("b", "2.3.4.5")
      |> put_req_header("c", "3.4.5.6")

    assert :peer == conn |> remote_ip(headers: ~w[])

    assert {1, 2, 3, 4} == conn |> remote_ip(headers: ~w[a])
    assert {2, 3, 4, 5} == conn |> remote_ip(headers: ~w[a b])
    assert {3, 4, 5, 6} == conn |> remote_ip(headers: ~w[a c])
    assert {3, 4, 5, 6} == conn |> remote_ip(headers: ~w[a b c])
    assert {3, 4, 5, 6} == conn |> remote_ip(headers: ~w[a c b])

    assert {2, 3, 4, 5} == conn |> remote_ip(headers: ~w[b])
    assert {2, 3, 4, 5} == conn |> remote_ip(headers: ~w[b a])
    assert {3, 4, 5, 6} == conn |> remote_ip(headers: ~w[b c])
    assert {3, 4, 5, 6} == conn |> remote_ip(headers: ~w[b a c])
    assert {3, 4, 5, 6} == conn |> remote_ip(headers: ~w[b c a])

    assert {3, 4, 5, 6} == conn |> remote_ip(headers: ~w[c])
    assert {3, 4, 5, 6} == conn |> remote_ip(headers: ~w[c a])
    assert {3, 4, 5, 6} == conn |> remote_ip(headers: ~w[c b])
    assert {3, 4, 5, 6} == conn |> remote_ip(headers: ~w[c a b])
    assert {3, 4, 5, 6} == conn |> remote_ip(headers: ~w[c b a])
  end

  test "allowed headers maintain relative ordering" do
    headers = ~w[a b c]

    a = fn conn -> put_req_header(conn, "a", "1.2.3.4") end
    b = fn conn -> put_req_header(conn, "b", "2.3.4.5") end
    c = fn conn -> put_req_header(conn, "c", "3.4.5.6") end

    assert :peer == @conn |> remote_ip(headers: headers)

    assert {1, 2, 3, 4} == @conn |> a.() |> remote_ip(headers: headers)
    assert {2, 3, 4, 5} == @conn |> a.() |> b.() |> remote_ip(headers: headers)
    assert {3, 4, 5, 6} == @conn |> a.() |> c.() |> remote_ip(headers: headers)
    assert {3, 4, 5, 6} == @conn |> a.() |> b.() |> c.() |> remote_ip(headers: headers)
    assert {2, 3, 4, 5} == @conn |> a.() |> c.() |> b.() |> remote_ip(headers: headers)

    assert {2, 3, 4, 5} == @conn |> b.() |> remote_ip(headers: headers)
    assert {1, 2, 3, 4} == @conn |> b.() |> a.() |> remote_ip(headers: headers)
    assert {3, 4, 5, 6} == @conn |> b.() |> c.() |> remote_ip(headers: headers)
    assert {3, 4, 5, 6} == @conn |> b.() |> a.() |> c.() |> remote_ip(headers: headers)
    assert {1, 2, 3, 4} == @conn |> b.() |> c.() |> a.() |> remote_ip(headers: headers)

    assert {3, 4, 5, 6} == @conn |> c.() |> remote_ip(headers: headers)
    assert {1, 2, 3, 4} == @conn |> c.() |> a.() |> remote_ip(headers: headers)
    assert {2, 3, 4, 5} == @conn |> c.() |> b.() |> remote_ip(headers: headers)
    assert {2, 3, 4, 5} == @conn |> c.() |> a.() |> b.() |> remote_ip(headers: headers)
    assert {1, 2, 3, 4} == @conn |> c.() |> b.() |> a.() |> remote_ip(headers: headers)
  end
end
