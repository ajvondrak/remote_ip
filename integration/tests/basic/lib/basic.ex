defmodule Basic do
  use Plug.Router

  plug RemoteIp
  plug :match
  plug :dispatch

  get "/ip" do
    send_resp(conn, 200, :inet.ntoa(conn.remote_ip))
  end
end
