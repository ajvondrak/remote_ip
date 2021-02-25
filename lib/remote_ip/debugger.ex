defmodule RemoteIp.Debugger do
  require Logger

  # TODO
  @moduledoc false

  defmacro debug(id, inputs \\ [], do: output) do
    if debug?(id) do
      quote do
        inputs = unquote(inputs)
        output = unquote(output)
        unquote(__MODULE__).__log__(unquote(id), inputs, output)
        output
      end
    else
      output
    end
  end

  @debug Application.get_env(:remote_ip, :debug, false)

  cond do
    is_list(@debug) ->
      defp debug?(id), do: Enum.member?(@debug, id)

    is_boolean(@debug) ->
      defp debug?(_), do: @debug
  end

  def __log__(id, inputs, output) do
    Logger.debug(__message__(id, inputs, output))
  end

  def __message__(:options, [], options) do
    headers = inspect(options[:headers])
    parsers = inspect(options[:parsers])
    proxies = inspect(options[:proxies] |> Enum.map(&InetCidr.to_string/1))
    clients = inspect(options[:clients] |> Enum.map(&InetCidr.to_string/1))

    [
      "Processing remote IP\n",
      "  headers: #{headers}\n",
      "  parsers: #{parsers}\n",
      "  proxies: #{proxies}\n",
      "  clients: #{clients}"
    ]
  end

  def __message__(:headers, [], headers) do
    "Taking forwarding headers from #{inspect(headers)}"
  end

  def __message__(:forwarding, [], headers) do
    "Parsing IPs from forwarding headers: #{inspect(headers)}"
  end

  def __message__(:ips, [], ips) do
    "Parsed IPs from forwarding headers: #{inspect(ips)}"
  end

  def __message__(:type, [ip], type) do
    case type do
      :client -> "#{inspect(ip)} is a known client IP"
      :proxy -> "#{inspect(ip)} is a known proxy IP"
      :reserved -> "#{inspect(ip)} is a reserved IP"
      :unknown -> "#{inspect(ip)} is an unknown IP, assuming it's the client"
    end
  end

  def __message__(:ip, [old_conn], new_conn) do
    origin = inspect(old_conn.remote_ip)
    client = inspect(new_conn.remote_ip)

    if client != origin do
      "Processed remote IP, found client #{client} to replace #{origin}"
    else
      "Processed remote IP, no client found to replace #{origin}"
    end
  end

  def __message__(:ip, [], ip) do
    if ip == nil do
      "Processed remote IP, no client found"
    else
      "Processed remote IP, found client #{inspect(ip)}"
    end
  end
end
