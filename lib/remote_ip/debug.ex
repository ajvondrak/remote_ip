defmodule RemoteIp.Debug do
  @moduledoc false # TODO

  defmacro __using__(_) do
    quote do
      require Logger
    end
  end

  defmacro log(id, inputs \\ [], do: output) do
    if enabled?(id) do
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

  @enabled Application.get_env(:remote_ip, :debug, false)

  cond do
    is_list(@enabled) ->
      defp enabled?(id), do: Enum.member?(@enabled, id)

    is_boolean(@enabled) ->
      defp enabled?(_), do: @enabled
  end

  @level Application.get_env(:remote_ip, :level, :debug)

  defmacro __log__(id, inputs, output) do
    quote do
      Logger.log(
        unquote(@level),
        RemoteIp.Debug.__message__(
          unquote(id),
          unquote(inputs),
          unquote(output)
        )
      )
    end
  end

  def __message__(:headers, [], headers) do
    "Processing remote IPs using known headers: #{inspect(headers)}"
  end

  def __message__(:proxies, [], proxies) do
    proxies = Enum.map(proxies, &InetCidr.to_string/1)
    "Processing remote IPs using known proxies: #{inspect(proxies)}"
  end

  def __message__(:clients, [], clients) do
    clients = Enum.map(clients, &InetCidr.to_string/1)
    "Processing remote IPs using known clients: #{inspect(clients)}"
  end

  def __message__(:req, [], headers) do
    "Processing remote IP from request headers: #{inspect(headers)}"
  end

  def __message__(:fwd, [], headers) do
    "Parsing IPs from known forwarding headers: #{inspect(headers)}"
  end

  def __message__(:ips, [], ips) do
    "Parsed IPs out of forwarding headers into: #{inspect(ips)}"
  end

  def __message__(:known_client, [ip], bool) do
    "#{inspect(ip)} in known clients? #{if bool, do: "yes", else: "no"}"
  end

  def __message__(:known_proxy, [ip], bool) do
    "#{inspect(ip)} in known proxies? #{if bool, do: "yes", else: "no"}"
  end

  def __message__(:reserved, [ip], bool) do
    "#{inspect(ip)} is a reserved IP? #{if bool, do: "yes", else: "no"}"
  end

  def __message__(:call, [old], new) do
    origin = inspect(old.remote_ip)
    client = inspect(new.remote_ip)

    if client != origin do
      "Processed remote IP, found client #{client} to replace #{origin}"
    else
      "Processed remote IP, no client found to replace #{origin}"
    end
  end

  def __message__(:from, [], ip) do
    if ip == nil do
      "Processed remote IP, no client found"
    else
      "Processed remote IP, found client #{inspect(ip)}"
    end
  end
end
