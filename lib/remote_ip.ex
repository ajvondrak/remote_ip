defmodule RemoteIp do
  import RemoteIp.Debugger

  @behaviour Plug

  @moduledoc """
  A plug to rewrite the `Plug.Conn`'s `remote_ip` based on forwarding headers.

  Generic comma-separated headers like `X-Forwarded-For`, `X-Real-Ip`, and
  `X-Client-Ip` are all recognized, as well as the [RFC
  7239](https://tools.ietf.org/html/rfc7239) `Forwarded` header. IPs are
  processed last-to-first to prevent IP spoofing. Read more in the [algorithm
  documentation](#algorithm).

  This plug is highly configurable, giving you the power to adapt it to your
  particular networking infrastructure:

  * IPs can come from any header(s) you want. You can even implement your own
    custom parser if you're using a special format.

  * You can configure the IPs of known proxies & clients so that you never get
    the wrong results.

  * All options are configurable at runtime, so you can deploy a single release
    but still customize it using environment variables, the `Application`
    environment, or any other arbitrary mechanism.

  * Still not getting the right IP? You can recompile the plug with debugging
    enabled to generate logs, and even fine-tune the verbosity by selecting
    which events to track.

  ## Usage

  This plug should be early in your pipeline, or else the `remote_ip` might not
  get rewritten before your route's logic executes.

  In [Phoenix](https://hexdocs.pm/phoenix), this might mean plugging `RemoteIp`
  into your endpoint before the router:

  ```elixir
  defmodule MyApp.Endpoint do
    use Phoenix.Endpoint, otp_app: :my_app

    plug RemoteIp
    # plug ...
    # plug ...
    plug MyApp.Router
  end
  ```

  But if you only want to rewrite IPs in a narrower part of your app, you could
  of course put it in an individual pipeline of your router.

  In an ordinary `Plug.Router`, you should make sure `RemoteIp` comes before
  the `:match`/`:dispatch` plugs:

  ```elixir
  defmodule MyApp do
    use Plug.Router

    plug RemoteIp
    plug :match
    plug :dispatch

    # get "/" do ...
  end
  ```

  You can also use `RemoteIp.from/2` to determine an IP from a list of headers.
  This is useful outside of the plug pipeline, where you may not have access to
  the `Plug.Conn`. For example, you might only be getting the `x_headers` from
  [`Phoenix.Socket`](https://hexdocs.pm/phoenix/Phoenix.Socket.html):

  ```elixir
  defmodule MySocket do
    use Phoenix.Socket

    def connect(params, socket, connect_info) do
      ip = RemoteIp.from(connect_info[:x_headers])
      # ...
    end
  end
  ```

  ## Configuration

  Options may be passed into `RemoteIp` (and `RemoteIp.from/2`) as a keyword
  list. At a high level, the following options are available:

  * `:headers` - a list of header names to consider
  * `:parsers` - a map from header names to custom parser modules
  * `:clients` - a list of known client IPs in CIDR notation
  * `:proxies` - a list of known proxy IPs in CIDR notation

  You can specify any option using a tuple of `{module, function_name,
  arguments}`, which will be called dynamically at runtime to get the
  equivalent value.

  For more details about these options, see `RemoteIp.Options`.

  ## Troubleshooting

  Getting the right configuration can be tricky. Requests might come in with
  unexpected headers, or maybe you didn't account for certain proxies, or any
  number of other issues.

  Luckily, you can debug `RemoteIp` (and `RemoteIp.from/2`) by updating your
  `Config` file:

  ```elixir
  config :remote_ip, debug: true
  ```

  and recompiling the `:remote_ip` dependency:

  ```console
  $ mix deps.clean --build remote_ip
  $ mix deps.compile
  ```

  Then it will generate log messages showing how the IP gets computed. For more
  details about these messages, as well advanced usage, see
  `RemoteIp.Debugger`.

  ## Metadata

  When you use this plug, it will populate the `Logger` metadata under the key
  `:remote_ip`. This will be the string representation of the final value of
  the `Plug.Conn`'s `remote_ip`. Even if no client was found in the headers, we
  still set the metadata to the original IP.

  You can use this in your logs by updating your `Config` file:

  ```elixir
  config :logger,
    message: "$metadata[$level] $message\\n",
    metadata: [:remote_ip]
  ```

  Then your logs will look something like this:

  ```log
  [info] Running ExampleWeb.Endpoint with cowboy 2.8.0 at 0.0.0.0:4000 (http)
  [info] Access ExampleWeb.Endpoint at http://localhost:4000
  remote_ip=1.2.3.4 [info] GET /
  remote_ip=1.2.3.4 [debug] Processing with ExampleWeb.PageController.index/2
    Parameters: %{}
    Pipelines: [:browser]
  remote_ip=1.2.3.4 [info] Sent 200 in 21ms
  ```

  Note that metadata will *not* be set by `RemoteIp.from/2`.
  """

  @impl Plug

  def init(opts) do
    RemoteIp.Options.pack(opts)
  end

  @impl Plug

  def call(conn, opts) do
    debug :ip, [conn] do
      ip = ip_from(conn.req_headers, opts) || conn.remote_ip
      add_metadata(ip)
      %{conn | remote_ip: ip}
    end
  end

  @doc """
  Extracts the remote IP from a list of headers.

  In cases where you don't have access to a full `Plug.Conn` struct, you can
  use this function to process the remote IP from a list of key-value pairs
  representing the headers.

  You may specify the same options as if you were using the plug. See
  `RemoteIp.Options` for details.

  If no client IP can be found in the given headers, this function will return
  `nil`.

  ## Examples

      iex> RemoteIp.from([{"x-forwarded-for", "1.2.3.4"}])
      {1, 2, 3, 4}

      iex> [{"x-foo", "1.2.3.4"}, {"x-bar", "2.3.4.5"}]
      ...> |> RemoteIp.from(headers: ~w[x-foo])
      {1, 2, 3, 4}

      iex> [{"x-foo", "1.2.3.4"}, {"x-bar", "2.3.4.5"}]
      ...> |> RemoteIp.from(headers: ~w[x-bar])
      {2, 3, 4, 5}

      iex> [{"x-foo", "1.2.3.4"}, {"x-bar", "2.3.4.5"}]
      ...> |> RemoteIp.from(headers: ~w[x-baz])
      nil
  """

  @spec from(Plug.Conn.headers(), keyword()) :: :inet.ip_address() | nil

  def from(headers, opts \\ []) do
    debug :ip do
      ip_from(headers, init(opts))
    end
  end

  defp ip_from(headers, opts) do
    opts = options_from(opts)
    client_from(ips_from(headers, opts), opts)
  end

  defp options_from(opts) do
    debug :options do
      RemoteIp.Options.unpack(opts)
    end
  end

  defp ips_from(headers, opts) do
    debug :ips do
      headers = forwarding_from(headers, opts)
      RemoteIp.Headers.parse(headers, opts[:parsers])
    end
  end

  defp forwarding_from(headers, opts) do
    debug :forwarding do
      debug(:headers, do: headers) |> RemoteIp.Headers.take(opts[:headers])
    end
  end

  defp client_from(ips, opts) do
    Enum.reverse(ips) |> Enum.find(&client?(&1, opts))
  end

  defp client?(ip, opts) do
    type(ip, opts) in [:client, :unknown]
  end

  # https://en.wikipedia.org/wiki/Loopback
  # https://en.wikipedia.org/wiki/Private_network
  # https://en.wikipedia.org/wiki/Reserved_IP_addresses
  @reserved ~w[
    127.0.0.0/8
    ::1/128
    fc00::/7
    10.0.0.0/8
    172.16.0.0/12
    192.168.0.0/16
  ] |> Enum.map(&RemoteIp.Block.parse!/1)

  defp type(ip, opts) do
    debug :type, [ip] do
      ip = RemoteIp.Block.encode(ip)

      cond do
        opts[:clients] |> contains?(ip) -> :client
        opts[:proxies] |> contains?(ip) -> :proxy
        @reserved |> contains?(ip) -> :reserved
        true -> :unknown
      end
    end
  end

  defp contains?(blocks, ip) do
    Enum.any?(blocks, &RemoteIp.Block.contains?(&1, ip))
  end

  defp add_metadata(remote_ip) do
    case :inet.ntoa(remote_ip) do
      {:error, _} -> :ok
      ip -> Logger.metadata(remote_ip: to_string(ip))
    end
  end
end
