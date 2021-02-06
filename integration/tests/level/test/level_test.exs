defmodule LevelTest do
  use ExUnit.Case
  import ExUnit.CaptureLog

  @opts [
    headers: ~w[xff],
    clients: ~w[192.168.0.1/32],
    proxies: ~w[1.2.3.4/32]
  ]

  @head [
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

  test "RemoteIp.call/2" do
    logs =
      capture_log(fn -> call(@conn, @opts) end)
      |> String.trim_trailing("\n")
      |> String.split("\n")

    refute Enum.empty?(logs)

    Enum.each(logs, fn log ->
      assert log =~ ~r/mfa=RemoteIp.* \[info\]/
    end)
  end

  test "RemoteIp.from/2" do
    logs =
      capture_log(fn -> from(@head, @opts) end)
      |> String.trim_trailing("\n")
      |> String.split("\n")

    refute Enum.empty?(logs)

    Enum.each(logs, fn log ->
      assert log =~ ~r/mfa=RemoteIp.* \[info\]/
    end)
  end
end
