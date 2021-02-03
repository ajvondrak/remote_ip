defmodule BasicTest do
  use ExUnit.Case
  use Plug.Test

  import ExUnit.CaptureLog

  def xff(conn, header) do
    put_req_header(conn, "x-forwarded-for", header)
  end

  def call(conn, opts \\ []) do
    Basic.call(conn, Basic.init(opts))
  end

  test "GET /ip" do
    conn = conn(:get, "/ip") |> xff("1.2.3.4,2.3.4.5,127.0.0.1")
    assert "" == capture_log(fn -> assert call(conn).resp_body == "2.3.4.5" end)
  end
end
