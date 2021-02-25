defmodule PurgeTest do
  use ExUnit.Case

  import ExUnit.CaptureLog

  @head [{"x-forwarded-for", "3.14.15.9"}]

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

  test "logs get purged at compile time" do
    Logger.configure(level: :debug)
    assert capture_log(fn -> call(@conn) end) == ""
    assert capture_log(fn -> from(@head) end) == ""
  end
end
