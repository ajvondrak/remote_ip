defmodule DebugTest do
  use ExUnit.Case
  import ExUnit.CaptureLog

  @opts [
    headers: ~w[xff],
    clients: ~w[192.168.0.1/32],
    proxies: ~w[1.2.3.4/32]
  ]

  @head [
    {"user-agent", "test"},
    {"x-forwarded-for", "3.14.15.9"},
    {"xff", "2.3.4.5, 192.168.0.1, 1.2.3.4, 10.0.0.1"}
  ]

  @conn %Plug.Conn{
    remote_ip: {127, 0, 0, 1},
    req_headers: @head
  }

  def call(conn, opts) do
    RemoteIp.call(conn, RemoteIp.init(opts))
  end

  def from(head, opts) do
    RemoteIp.from(head, opts)
  end

  test "hit with RemoteIp.call/2" do
    assert capture_log(fn -> call(@conn, @opts) end) == """
           [debug] Processing remote IPs using known headers: ["xff"]
           [debug] Processing remote IPs using known proxies: ["1.2.3.4/32"]
           [debug] Processing remote IPs using known clients: ["192.168.0.1/32"]
           [debug] Processing remote IP from request headers: [{"user-agent", "test"}, {"x-forwarded-for", "3.14.15.9"}, {"xff", "2.3.4.5, 192.168.0.1, 1.2.3.4, 10.0.0.1"}]
           [debug] Parsing IPs from known forwarding headers: [{"xff", "2.3.4.5, 192.168.0.1, 1.2.3.4, 10.0.0.1"}]
           [debug] Parsed IPs out of forwarding headers into: [{2, 3, 4, 5}, {192, 168, 0, 1}, {1, 2, 3, 4}, {10, 0, 0, 1}]
           [debug] {10, 0, 0, 1} in known clients? no
           [debug] {10, 0, 0, 1} in known proxies? no
           [debug] {10, 0, 0, 1} is a reserved IP? yes
           [debug] {1, 2, 3, 4} in known clients? no
           [debug] {1, 2, 3, 4} in known proxies? yes
           [debug] {192, 168, 0, 1} in known clients? yes
           [debug] Processed remote IP, found client {192, 168, 0, 1} to replace {127, 0, 0, 1}
           """
  end

  test "miss with RemoteIp.call/2" do
    assert capture_log(fn -> call(@conn, headers: []) end) == """
           [debug] Processing remote IPs using known headers: []
           [debug] Processing remote IPs using known proxies: []
           [debug] Processing remote IPs using known clients: []
           [debug] Processing remote IP from request headers: [{"user-agent", "test"}, {"x-forwarded-for", "3.14.15.9"}, {"xff", "2.3.4.5, 192.168.0.1, 1.2.3.4, 10.0.0.1"}]
           [debug] Parsing IPs from known forwarding headers: []
           [debug] Parsed IPs out of forwarding headers into: []
           [debug] Processed remote IP, no client found to replace {127, 0, 0, 1}
           """
  end

  test "hit with RemoteIp.from/2" do
    assert capture_log(fn -> from(@head, @opts) end) == """
           [debug] Processing remote IPs using known headers: ["xff"]
           [debug] Processing remote IPs using known proxies: ["1.2.3.4/32"]
           [debug] Processing remote IPs using known clients: ["192.168.0.1/32"]
           [debug] Processing remote IP from request headers: [{"user-agent", "test"}, {"x-forwarded-for", "3.14.15.9"}, {"xff", "2.3.4.5, 192.168.0.1, 1.2.3.4, 10.0.0.1"}]
           [debug] Parsing IPs from known forwarding headers: [{"xff", "2.3.4.5, 192.168.0.1, 1.2.3.4, 10.0.0.1"}]
           [debug] Parsed IPs out of forwarding headers into: [{2, 3, 4, 5}, {192, 168, 0, 1}, {1, 2, 3, 4}, {10, 0, 0, 1}]
           [debug] {10, 0, 0, 1} in known clients? no
           [debug] {10, 0, 0, 1} in known proxies? no
           [debug] {10, 0, 0, 1} is a reserved IP? yes
           [debug] {1, 2, 3, 4} in known clients? no
           [debug] {1, 2, 3, 4} in known proxies? yes
           [debug] {192, 168, 0, 1} in known clients? yes
           [debug] Processed remote IP, found client {192, 168, 0, 1}
           """
  end

  test "miss with RemoteIp.from/2" do
    assert capture_log(fn -> from(@head, headers: []) end) == """
           [debug] Processing remote IPs using known headers: []
           [debug] Processing remote IPs using known proxies: []
           [debug] Processing remote IPs using known clients: []
           [debug] Processing remote IP from request headers: [{"user-agent", "test"}, {"x-forwarded-for", "3.14.15.9"}, {"xff", "2.3.4.5, 192.168.0.1, 1.2.3.4, 10.0.0.1"}]
           [debug] Parsing IPs from known forwarding headers: []
           [debug] Parsed IPs out of forwarding headers into: []
           [debug] Processed remote IP, no client found
           """
  end
end
