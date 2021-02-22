defmodule ParsersTest do
  use ExUnit.Case
  use Plug.Test

  import ExUnit.CaptureLog

  def call(conn, opts \\ []) do
    Parsers.call(conn, Parsers.init(opts))
  end

  test "GET /ip" do
    head = [
      {"forwarding", "client=1.2.3.4"},
      {"forwarding", "proxy=10.20.30.40"},
      {"forwarding", "client=2.3.4.5"},
      {"forwarding", "proxy=20.30.40.50"}
    ]

    conn = %{conn(:get, "/ip") | req_headers: head}

    logs = capture_log(fn -> assert call(conn).resp_body == "2.3.4.5" end)

    assert logs == """
           [debug] Processing remote IP
             headers: ["forwarding"]
             parsers: %{"forwarded" => RemoteIp.Parsers.Forwarded, "forwarding" => Parsers.Forwarding}
             proxies: []
             clients: []
           [debug] Parsed IPs from forwarding headers: [{1, 2, 3, 4}, {2, 3, 4, 5}]
           """
  end
end
