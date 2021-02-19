defmodule CustomTest do
  use ExUnit.Case
  import ExUnit.CaptureLog

  @head [
    {"user-agent", "test"},
    {"x-forwarded-for", "3.14.15.9, 26.53.58.97, 93.238.46.26"}
  ]

  @conn %Plug.Conn{
    remote_ip: {127, 0, 0, 1},
    req_headers: @head
  }

  def call(conn, opts \\ []) do
    RemoteIp.call(conn, RemoteIp.init(opts))
  end

  def from(head, opts \\ []) do
    RemoteIp.from(head, opts)
  end

  test "hit with RemoteIp.call/2" do
    assert capture_log(fn -> call(@conn) end) == """
           [info] Parsed IPs from forwarding headers: [{3, 14, 15, 9}, {26, 53, 58, 97}, {93, 238, 46, 26}]
           [info] Processed remote IP, found client {93, 238, 46, 26} to replace {127, 0, 0, 1}
           """
  end

  test "miss with RemoteIp.call/2" do
    assert capture_log(fn -> call(@conn, headers: []) end) == """
           [info] Parsed IPs from forwarding headers: []
           [info] Processed remote IP, no client found to replace {127, 0, 0, 1}
           """
  end

  test "hit with RemoteIp.from/2" do
    assert capture_log(fn -> from(@head) end) == """
           [info] Parsed IPs from forwarding headers: [{3, 14, 15, 9}, {26, 53, 58, 97}, {93, 238, 46, 26}]
           [info] Processed remote IP, found client {93, 238, 46, 26}
           """
  end

  test "miss with RemoteIp.from/2" do
    assert capture_log(fn -> from(@head, headers: []) end) == """
           [info] Parsed IPs from forwarding headers: []
           [info] Processed remote IP, no client found
           """
  end
end
