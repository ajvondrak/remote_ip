defmodule RemoteIp.Options do
  @headers ~w[forwarded x-forwarded-for x-client-ip x-real-ip]
  @parsers %{"forwarded" => RemoteIp.Parsers.Forwarded}
  @proxies []
  @clients []

  @moduledoc """
  The keyword options given to `RemoteIp.init/1` or `RemoteIp.from/2`.

  You shouldn't need to use this module directly. Its functions are used
  internally by `RemoteIp` to process configurations and support MFA-style
  [runtime options](#module-runtime-options).

  You may pass any of the following keyword arguments into the plug (they get
  passed to `RemoteIp.init/1`). You can also pass the same keywords directly to
  `RemoteIp.from/2`.

  ## `:headers`

  The `:headers` option should be a list of strings. These are the names of
  headers that contain forwarding information. The default is

  ```elixir
  #{inspect(@headers, pretty: true)}
  ```

  Every request header whose name exactly matches one of these strings will be
  parsed for IP addresses, which are then used to determine the routing
  information and ultimately the original client IP. Note that `Plug`
  normalizes headers to lowercase, so this option should consist of lowercase
  names.

  In production, you likely want this to be a singleton - a list of only one
  string. There are a couple reasons:

  1. You usually can't rely on servers to preserve the relative ordering of
     headers in the HTTP request. For example, the
     [Cowboy](https://github.com/ninenines/cowboy/) server presently [uses
     maps](https://github.com/elixir-plug/plug_cowboy/blob/f82f2ff982f04fb4faa3a12fd2b08a7cc56ebe15/lib/plug/cowboy/conn.ex#L125-L127)
     to represent headers, which don't preserve key order. The order in which
     we process IPs matters because we take that as the routing information for
     the request. So if you have multiple competing headers, the routing might
     be ambiguous, and you could get bad results.

  2. It could also be a security issue. Say you're only expecting one header
     like `X-Forwarded-For`, but configure multiple headers like
     `["x-forwarded-for", "x-real-ip"]`. Then it'd be easy for a malicious user
     to just set an extra `X-Real-Ip` header and interfere with the IP parsing
     (again, due to the sensitive nature of header ordering).

  We still allow multiple headers because:

  1. Users can get up & running faster if the default configuration recognizes
     all of the common headers.

  2. You shouldn't be relying that heavily on IP addresses for security. Even a
     single plain-text header has enough problems on its own that we can't
     guarantee its results are accurate. For more details, see the
     documentation for [the algorithm](algorithm.md).

  3. It's more general. Networking setups are often very idiosyncratic, and we
     want to give users the option to use multiple headers if that's what they
     need.

  ## `:parsers`

  The `:parsers` option should be a map from strings to modules. Each string
  should be a header name (lowercase), and each module should implement the
  `RemoteIp.Parser` behaviour. The default is


  ```elixir
  #{inspect(@parsers, pretty: true)}
  ```

  Headers with the given name are parsed using the given module. If a header is
  not found in this map, it will be parsed by `RemoteIp.Parsers.Generic`. So
  you can use this option to:

  * add a parser for your own custom header

  * specialize on the generic parsing of headers like `"x-forwarded-for"`

  * replace any of the default parsers with one of your own

  The map you provide for this option is automatically merged into the default
  using `Map.merge/2`. That way, the stock parsers won't be overridden unless
  you explicitly provide your own replacement.

  ## `:proxies`

  The `:proxies` option should be a list of strings - either individual IPs or
  ranges in
  [CIDR](https://en.wikipedia.org/wiki/Classless_Inter-Domain_Routing)
  notation. The default is


  ```elixir
  #{inspect(@proxies, pretty: true)}
  ```

  For the sake of efficiency, you should prefer CIDR notation where possible.
  So instead of listing out 256 different addresses for the `1.2.3.x` block,
  you should say `"1.2.3.0/24"`.

  These proxies are skipped by [the algorithm](algorithm.md) and are never
  considered the original client IP, unless specifically overruled by the
  `:clients` option.

  In addition to the proxies listed here, note that the following [reserved IP
  addresses](https://en.wikipedia.org/wiki/Reserved_IP_addresses) are also
  skipped automatically, as they are presumed to be internal addresses that
  don't belong to the client:

  * IPv4 loopback: `127.0.0.0/8`
  * IPv6 loopback: `::1/128`
  * IPv4 private network: `10.0.0.0/8`, `172.16.0.0/12`, `192.168.0.0/16`
  * IPv6 unique local address: `fc00::/7`

  ## `:clients`

  The `:clients` option should be a list of strings - either individual IPs or
  ranges in
  [CIDR](https://en.wikipedia.org/wiki/Classless_Inter-Domain_Routing)
  notation. The default is


  ```elixir
  #{inspect(@clients, pretty: true)}
  ```

  For the sake of efficiency, you should prefer CIDR notation where possible.
  So instead of listing out 256 different addresses for the `1.2.3.x` block,
  you should say `"1.2.3.0/24"`.

  These addresses are never considered to be proxies by [the
  algorithm](algorithm.md). For example, if you configure the `:proxies` option
  to include `"1.2.3.0/24"` and the `:clients` option to include `"1.2.3.4"`,
  then every IP in the `1.2.3.x` block would be considered a proxy *except* for
  `1.2.3.4`.

  This option can also be used on reserved IP addresses that would otherwise be
  skipped automatically. For example, if your routing works through a local
  network, you might actually consider addresses in the `10.x.x.x` block to be
  clients. You could permit the entire block with `"10.0.0.0/8"`, or even
  specific IPs in this range like `"10.1.2.3"`.

  ## Runtime options

  Every option can also accept a tuple of three elements: `{module, function,
  arguments}` (MFA). These are passed to `Kernel.apply/3` at runtime, allowing
  you to dynamically configure the plug, even though the `Plug.Builder`
  generally calls `c:Plug.init/1` at compilation time.

  The return value from an MFA should be the same as if you were passing the
  literal into that option. For instance, the `:proxies` MFA should return a
  list of IP/CIDR strings.

  The MFAs you give are re-evaluated on *each call* to `RemoteIp.call/2` or
  `RemoteIp.from/2`. So be careful not to do anything too expensive at runtime.
  For example, don't download a list of known proxies, or else it will be
  re-downloaded on every request. Consider caching the download instead,
  perhaps using a library like [`Cachex`](https://hexdocs.pm/cachex).

  ## Examples

  ### Basic usage

  Suppose you know:
  * you are behind proxies in the `1.2.x.x` block
  * the proxies use the `X-Real-Ip` header
  * but the IP `1.2.3.4` is actually a client, not one of the proxies

  Then you could say:

  ```elixir
  defmodule MyApp do
    use Plug.Router

    plug RemoteIp,
      headers: ~w[x-real-ip],
      proxies: ~w[1.2.0.0/16],
      clients: ~w[1.2.3.4]

    plug :match
    plug :dispatch

    # get "/" do ...
  end
  ```

  The same options may also be passed into `RemoteIp.from/2`:

  ```elixir
  defmodule MySocket do
    use Phoenix.Socket

    @options [
      headers: ~w[x-real-ip],
      proxies: ~w[1.2.0.0/16],
      clients: ~w[1.2.3.4]
    ]

    def connect(params, socket, connect_info) do
      ip = RemoteIp.from(connect_info[:x_headers], @options)
      # ...
    end
  end
  ```

  ### Custom parser

  Suppose your proxies are using a header with a special format. The name of
  the header is `X-Special` and the format looks like `ip=127.0.0.1`.

  First, you'd implement a custom parser:

  ```elixir
  defmodule SpecialParser do
    @behaviour RemoteIp.Parser

    @impl RemoteIp.Parser
    def parse(header) do
      ip = String.replace_prefix(header, "ip=", "")
      case :inet.parse_strict_address(ip |> to_charlist()) do
        {:ok, parsed} -> [parsed]
        _ -> []
      end
    end
  end
  ```

  Then you would configure the plug with that parser. Make sure to also specify
  the `:headers` option so that the `X-Special` header actually gets passed to
  the parser.

  ```elixir
  defmodule SpecialApp do
    use Plug.Router

    plug RemoteIp,
      headers: ~w[x-special],
      parsers: %{"x-special" => SpecialParser}

    plug :match
    plug :dispatch

    # get "/" do ...
  end
  ```

  ### Using MFAs

  Suppose you're deploying a release and you want to get the proxy IPs from an
  environment variable. Because the release is compiled ahead of time, you
  shouldn't do a `System.get_env/1` inline - it'll just be the value of the
  environment variable circa compilation time (probably empty!).

  ```elixir
  defmodule CompiledApp do
    use Plug.Router

    # DON'T DO THIS: the value of the env var gets compiled into the release
    plug RemoteIp, proxies: System.get_env("PROXIES") |> String.split(",")

    plug :match
    plug :dispatch

    # get "/" do ...
  end
  ```

  Instead, you can use an MFA to look up the variable at runtime:

  ```elixir
  defmodule RuntimeApp do
    use Plug.Router

    plug RemoteIp, proxies: {__MODULE__, :proxies, []}

    def proxies do
      System.get_env("PROXIES") |> String.split(",", trim: true)
    end

    plug :match
    plug :dispatch

    # get "/" do ...
  end
  ```
  """

  @doc """
  The default value for the given option.
  """

  def default(option)
  def default(:headers), do: @headers
  def default(:parsers), do: @parsers
  def default(:proxies), do: @proxies
  def default(:clients), do: @clients

  @doc """
  Processes keyword options, delaying the evaluation of MFAs until `unpack/1`.
  """

  def pack(options) do
    [
      headers: pack(options, :headers),
      parsers: pack(options, :parsers),
      proxies: pack(options, :proxies),
      clients: pack(options, :clients)
    ]
  end

  defp pack(options, option) do
    case Keyword.get(options, option, default(option)) do
      {m, f, a} -> {m, f, a}
      value -> evaluate(option, value)
    end
  end

  @doc """
  Evaluates options processed by `pack/1`, applying MFAs as needed.
  """

  def unpack(options) do
    [
      headers: unpack(options, :headers),
      parsers: unpack(options, :parsers),
      proxies: unpack(options, :proxies),
      clients: unpack(options, :clients)
    ]
  end

  defp unpack(options, option) do
    case Keyword.get(options, option) do
      {m, f, a} -> evaluate(option, apply(m, f, a))
      value -> value
    end
  end

  defp evaluate(:headers, headers) do
    headers
  end

  defp evaluate(:parsers, parsers) do
    Map.merge(default(:parsers), parsers)
  end

  defp evaluate(:proxies, proxies) do
    proxies |> Enum.map(&RemoteIp.Block.parse!/1)
  end

  defp evaluate(:clients, clients) do
    clients |> Enum.map(&RemoteIp.Block.parse!/1)
  end
end
