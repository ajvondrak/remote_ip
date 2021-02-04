defmodule RemoteIp.Debug do
  @moduledoc false # TODO

  defmacro log(id, inputs \\ [], do: output) do
    if Application.get_env(:remote_ip, :debug, false) do
      quote do
        inputs = unquote(inputs)
        output = unquote(output)
        RemoteIp.Debug.__log__(unquote(id), inputs, output)
        output
      end
    else
      output
    end
  end

  require Logger

  def __log__(id, inputs, output) do
    Logger.debug(message_for(id, inputs, output))
  end

  defp message_for(:headers, [], headers) do
    "Processing remote IPs using known headers: #{inspect(headers)}"
  end

  defp message_for(:proxies, [], proxies) do
    proxies = Enum.map(proxies, &InetCidr.to_string/1)
    "Processing remote IPs using known proxies: #{inspect(proxies)}"
  end

  defp message_for(:clients, [], clients) do
    clients = Enum.map(clients, &InetCidr.to_string/1)
    "Processing remote IPs using known clients: #{inspect(clients)}"
  end

  defp message_for(:req, [], headers) do
    "Processing remote IP from request headers: #{inspect(headers)}"
  end

  defp message_for(:fwd, [], headers) do
    "Parsing IPs from known forwarding headers: #{inspect(headers)}"
  end

  defp message_for(:ips, [], ips) do
    "Parsed IPs out of forwarding headers into: #{inspect(ips)}"
  end

  defp message_for(:known_client, [ip], bool) do
    "#{inspect(ip)} in known clients? #{if bool, do: "yes", else: "no"}"
  end

  defp message_for(:known_proxy, [ip], bool) do
    "#{inspect(ip)} in known proxies? #{if bool, do: "yes", else: "no"}"
  end

  defp message_for(:reserved, [ip], bool) do
    "#{inspect(ip)} is a reserved IP? #{if bool, do: "yes", else: "no"}"
  end

  defp message_for(:call, [old], new) do
    origin = inspect(old.remote_ip)
    client = inspect(new.remote_ip)

    if client != origin do
      "Processed remote IP, found client #{client} to replace #{origin}"
    else
      "Processed remote IP, no client found to replace #{origin}"
    end
  end

  defp message_for(:from, [], ip) do
    if ip == nil do
      "Processed remote IP, no client found"
    else
      "Processed remote IP, found client #{inspect(ip)}"
    end
  end

  # TODO: remove this clause after fleshing out all the possible message IDs
  defp message_for(id, inputs, output) do
    inspect([id: id, inputs: inputs, output: output], pretty: true)
  end
end
