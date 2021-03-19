defmodule RemoteIp.Debugger do
  require Logger

  @moduledoc """
  Compile-time debugging facilities.

  `RemoteIp` uses the `debug/3` macro to instrument its implementation with
  *debug events* at compile time. If an event is enabled, the macro will expand
  into a `Logger.debug/2` call with a specific message. If an event is
  disabled, the logging will be purged, thus generating no extra code and
  having no impact on run time.

  ## Basic usage

  Events are fired on every call to `RemoteIp.call/2` or `RemoteIp.from/2`. To
  enable or disable all debug events at once, you can set a boolean in your
  `Config` file:

  ```elixir
  config :remote_ip, debug: true
  ```

  By default, the debugger is turned off (i.e., `debug: false`).

  Because `RemoteIp.Debugger` works at compile time, you must make sure to
  recompile the `:remote_ip` dependency whenever you change the configuration:

  ```console
  $ mix deps.clean --build remote_ip
  ```

  ## Advanced usage

  You may also pass a list of atoms into the `:debug` configuration naming
  which events to log.

  These are all the possible events:

  * `:options` - the keyword options *after* any runtime configuration has been
    evaluated (see `RemoteIp.Options`)

  * `:headers` - all incoming headers, either from the `Plug.Conn`'s
    `req_headers` or the list passed directly into `RemoteIp.from/2`; useful
    for seeing if you're even getting the forwarding headers you expect in the
    first place

  * `:forwarding` - the subset of headers (as configured by `RemoteIp.Options`)
    that contain forwarding information

  * `:ips` - the entire sequence of IP addresses parsed from the forwarding
    headers, in order

  * `:type` - for each IP (until we find the client), classifies the address
    either as a known client, a known proxy, a reserved address, or none of the
    above (and thus presumably a client)

  * `:ip` - the final result of the remote IP processing; when rewriting the
    `Plug.Conn`'s `remote_ip`, the message will tell you the original IP that
    is being replaced

  Therefore, `debug: true` is equivalent to passing in all of the above:

  ```elixir
  config :remote_ip, debug: [:options, :headers, :forwarding, :ips, :type, :ip]
  ```

  But you could disable certain events by removing them from the list. For
  example, to log only the incoming headers and resulting IP:

  ```elixir
  config :remote_ip, debug: [:headers, :ip]
  ```

  ## Interactions with `Logger`

  Since they both work at compile time, your configuration of `:logger` will
  also affect the operation of `RemoteIp.Debugger`. For example, it's possible
  to enable debugging but still purge all the resulting logs:

  ```elixir
  # All events *would* be logged...
  config :remote_ip, debug: true

  # ...But :debug logs will actually get purged at compile time
  config :logger, compile_time_purge_matching: [[level_lower_than: :info]]
  ```
  """

  @doc """
  An internal macro for generating debug logs.

  There is no reason for you to call this directly. It's used to instrument the
  `RemoteIp` module at compilation time.
  """

  @spec debug(atom(), [any()], do: any()) :: any()

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

  if Version.match?(System.version(), "~> 1.10") do
    @debug Application.compile_env(:remote_ip, :debug, false)
  else
    @debug Application.get_env(:remote_ip, :debug, false)
  end

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
    proxies = inspect(options[:proxies] |> Enum.map(&to_string/1))
    clients = inspect(options[:clients] |> Enum.map(&to_string/1))

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
