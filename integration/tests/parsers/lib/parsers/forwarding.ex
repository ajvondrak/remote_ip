defmodule Parsers.Forwarding do
  @behaviour RemoteIp.Parser

  @impl RemoteIp.Parser

  def parse(value) do
    [type, address] = String.split(value, "=")

    case type do
      "proxy" ->
        []

      "client" ->
        {:ok, ip} = :inet.parse_strict_address(address |> to_charlist())
        [ip]
    end
  end
end
