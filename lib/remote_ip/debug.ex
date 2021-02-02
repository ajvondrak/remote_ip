defmodule RemoteIp.Debug do
  @moduledoc false

  @doc """
  A more ergonomic wrapper for `Logger.debug/2`.

  While `RemoteIp` could use `Logger` directly, it has several shortcomings.

  Most importantly, the code is harder to read when there are too many
  intervening log statements. The prevailing pattern is to capture some
  intermediate result being computed by a function, log that value, then return
  that value back from the function. This winds up looking like

     def function do
       value = ...
       Logger.debug(["function returns: ", value])
       value
     end

  which gets even messier when the return value takes more than one line to
  compute.

  Instead, this macro improves on the readability by (a) letting you wrap the
  body and (b) using the return value to generate the message automatically.
  The pattern then looks like

    def function do
      RemoteIp.Debug.log("function returns") do
        .
        .
        .
      end
    end

  By using our own macro, we can also make the experience better for the user
  when they want to disable the (admittedly noisy) `RemoteIp` logging.
  Normally, you'd have to manually configure the `:compile_time_purge_matching`
  option for `Logger` with the right metadata so that the raw `Logger.debug/2`
  statements would compile away. But since we're abstracting over that, we can
  introduce our own configuration, like so:

    config :remote_ip, debug: true|false

  At compile time, this macro will check the application environment. When
  debugging is disabled, the macro will just expand into the provided block -
  no extra logging code. When enabled, the macro will expand into the right
  `Logger.debug/2` incantations without interfering with the block's return
  value. (If you really want, you could still purge those statements in the
  usual way.)
  """

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

  # TODO: remove this clause; it's for temporary backwards compatibility
  defp message_for(msg, _, output) when is_binary(msg) do
    "#{msg}: #{inspect(output)}"
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

  # TODO: remove this clause after fleshing out all the possible message IDs
  defp message_for(id, inputs, output) do
    inspect([id: id, inputs: inputs, output: output], pretty: true)
  end
end
