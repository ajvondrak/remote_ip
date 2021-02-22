defmodule Parsers do
  use Plug.Router

  plug RemoteIp,
    headers: ~w[forwarding],
    parsers: %{"forwarding" => Parsers.Forwarding}

  plug :match
  plug :dispatch

  get "/ip" do
    send_resp(conn, 200, :inet.ntoa(conn.remote_ip))
  end
end
