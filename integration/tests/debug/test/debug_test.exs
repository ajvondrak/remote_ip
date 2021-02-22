defmodule DebugTest do
  use ExUnit.Case

  import ExUnit.CaptureLog

  @head [
    {"accept", "*/*"},
    {"x-forwarded-for", "3.14.15.9"},
    {"xff", "1.2.3.4, 10.0.0.1, 2.3.4.5"}
  ]

  @conn %Plug.Conn{
    remote_ip: {127, 0, 0, 1},
    req_headers: @head
  }

  def call(opts) do
    RemoteIp.call(@conn, RemoteIp.init(opts))
  end

  def from(opts) do
    RemoteIp.from(@head, opts)
  end

  describe "RemoteIp.call/2" do
    test "no client" do
      opts = [
        headers: ~w[xff],
        proxies: ~w[1.2.0.0/16 2.3.4.5/32],
        clients: ~w[]
      ]

      assert capture_log(fn -> call(opts) end) == """
             [debug] Processing remote IP
               headers: ["xff"]
               parsers: %{"forwarded" => RemoteIp.Parsers.Forwarded}
               proxies: ["1.2.0.0/16", "2.3.4.5/32"]
               clients: []
             [debug] Taking forwarding headers from [{"accept", "*/*"}, {"x-forwarded-for", "3.14.15.9"}, {"xff", "1.2.3.4, 10.0.0.1, 2.3.4.5"}]
             [debug] Parsing IPs from forwarding headers: [{"xff", "1.2.3.4, 10.0.0.1, 2.3.4.5"}]
             [debug] Parsed IPs from forwarding headers: [{1, 2, 3, 4}, {10, 0, 0, 1}, {2, 3, 4, 5}]
             [debug] {2, 3, 4, 5} is a known proxy IP
             [debug] {10, 0, 0, 1} is a reserved IP
             [debug] {1, 2, 3, 4} is a known proxy IP
             [debug] Processed remote IP, no client found to replace {127, 0, 0, 1}
             """
    end

    test "known client" do
      opts = [
        headers: ~w[xff],
        proxies: ~w[1.2.0.0/16 2.3.4.5/32],
        clients: ~w[1.2.3.4/32]
      ]

      assert capture_log(fn -> call(opts) end) == """
             [debug] Processing remote IP
               headers: ["xff"]
               parsers: %{"forwarded" => RemoteIp.Parsers.Forwarded}
               proxies: ["1.2.0.0/16", "2.3.4.5/32"]
               clients: ["1.2.3.4/32"]
             [debug] Taking forwarding headers from [{"accept", "*/*"}, {"x-forwarded-for", "3.14.15.9"}, {"xff", "1.2.3.4, 10.0.0.1, 2.3.4.5"}]
             [debug] Parsing IPs from forwarding headers: [{"xff", "1.2.3.4, 10.0.0.1, 2.3.4.5"}]
             [debug] Parsed IPs from forwarding headers: [{1, 2, 3, 4}, {10, 0, 0, 1}, {2, 3, 4, 5}]
             [debug] {2, 3, 4, 5} is a known proxy IP
             [debug] {10, 0, 0, 1} is a reserved IP
             [debug] {1, 2, 3, 4} is a known client IP
             [debug] Processed remote IP, found client {1, 2, 3, 4} to replace {127, 0, 0, 1}
             """
    end

    test "assumed client" do
      opts = [
        headers: ~w[xff],
        proxies: ~w[2.3.4.5/32],
        clients: ~w[]
      ]

      assert capture_log(fn -> call(opts) end) == """
             [debug] Processing remote IP
               headers: ["xff"]
               parsers: %{"forwarded" => RemoteIp.Parsers.Forwarded}
               proxies: ["2.3.4.5/32"]
               clients: []
             [debug] Taking forwarding headers from [{"accept", "*/*"}, {"x-forwarded-for", "3.14.15.9"}, {"xff", "1.2.3.4, 10.0.0.1, 2.3.4.5"}]
             [debug] Parsing IPs from forwarding headers: [{"xff", "1.2.3.4, 10.0.0.1, 2.3.4.5"}]
             [debug] Parsed IPs from forwarding headers: [{1, 2, 3, 4}, {10, 0, 0, 1}, {2, 3, 4, 5}]
             [debug] {2, 3, 4, 5} is a known proxy IP
             [debug] {10, 0, 0, 1} is a reserved IP
             [debug] {1, 2, 3, 4} is an unknown IP, assuming it's the client
             [debug] Processed remote IP, found client {1, 2, 3, 4} to replace {127, 0, 0, 1}
             """
    end
  end

  describe "RemoteIp.from/2" do
    test "no client" do
      opts = [
        headers: ~w[],
        proxies: ~w[1.2.0.0/16 2.3.4.5/32],
        clients: ~w[1.0.0.0/8 2.0.0.0/8 3.0.0.0/8]
      ]

      assert capture_log(fn -> from(opts) end) == """
             [debug] Processing remote IP
               headers: []
               parsers: %{"forwarded" => RemoteIp.Parsers.Forwarded}
               proxies: ["1.2.0.0/16", "2.3.4.5/32"]
               clients: ["1.0.0.0/8", "2.0.0.0/8", "3.0.0.0/8"]
             [debug] Taking forwarding headers from [{"accept", "*/*"}, {"x-forwarded-for", "3.14.15.9"}, {"xff", "1.2.3.4, 10.0.0.1, 2.3.4.5"}]
             [debug] Parsing IPs from forwarding headers: []
             [debug] Parsed IPs from forwarding headers: []
             [debug] Processed remote IP, no client found
             """
    end

    test "known client" do
      opts = [
        headers: ~w[x-forwarded-for],
        proxies: ~w[1.2.0.0/16 2.3.4.5/32],
        clients: ~w[3.0.0.0/8]
      ]

      assert capture_log(fn -> from(opts) end) == """
             [debug] Processing remote IP
               headers: ["x-forwarded-for"]
               parsers: %{"forwarded" => RemoteIp.Parsers.Forwarded}
               proxies: ["1.2.0.0/16", "2.3.4.5/32"]
               clients: ["3.0.0.0/8"]
             [debug] Taking forwarding headers from [{"accept", "*/*"}, {"x-forwarded-for", "3.14.15.9"}, {"xff", "1.2.3.4, 10.0.0.1, 2.3.4.5"}]
             [debug] Parsing IPs from forwarding headers: [{"x-forwarded-for", "3.14.15.9"}]
             [debug] Parsed IPs from forwarding headers: [{3, 14, 15, 9}]
             [debug] {3, 14, 15, 9} is a known client IP
             [debug] Processed remote IP, found client {3, 14, 15, 9}
             """
    end

    test "assumed client" do
      opts = [
        headers: ~w[x-forwarded-for xff],
        proxies: ~w[2.3.4.5/32 3.0.0.0/8],
        clients: ~w[]
      ]

      assert capture_log(fn -> from(opts) end) == """
             [debug] Processing remote IP
               headers: ["x-forwarded-for", "xff"]
               parsers: %{"forwarded" => RemoteIp.Parsers.Forwarded}
               proxies: ["2.3.4.5/32", "3.0.0.0/8"]
               clients: []
             [debug] Taking forwarding headers from [{"accept", "*/*"}, {"x-forwarded-for", "3.14.15.9"}, {"xff", "1.2.3.4, 10.0.0.1, 2.3.4.5"}]
             [debug] Parsing IPs from forwarding headers: [{"x-forwarded-for", "3.14.15.9"}, {"xff", "1.2.3.4, 10.0.0.1, 2.3.4.5"}]
             [debug] Parsed IPs from forwarding headers: [{3, 14, 15, 9}, {1, 2, 3, 4}, {10, 0, 0, 1}, {2, 3, 4, 5}]
             [debug] {2, 3, 4, 5} is a known proxy IP
             [debug] {10, 0, 0, 1} is a reserved IP
             [debug] {1, 2, 3, 4} is an unknown IP, assuming it's the client
             [debug] Processed remote IP, found client {1, 2, 3, 4}
             """
    end
  end
end
