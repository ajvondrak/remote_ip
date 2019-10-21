defmodule RemoteIp.Config do
  @moduledoc """
  The internal configuration used by `RemoteIp`.

  **This module is for internal use.** It defines a struct that holds the
  options parsed out of the keywords given to `RemoteIp.init/1`. Users should
  pass keywords into the `plug` macro (or into `RemoteIp.from/2`) as documented
  by `RemoteIp`.

  The only real difference between the keywords users would pass and the fields
  held by this struct is that the struct uses more efficient data structures
  that have been preprocessed by `RemoteIp.init/1`:

  * `headers` - Forwarding headers converted to a `MapSet` for efficient
    membership checks.

  * `proxies` - Known proxy IP ranges parsed by `InetCidr.parse/1`.

  * `clients` - Known client IP ranges parsed by `InetCidr.parse/1`.
  """

  @type cidr :: {:inet.ip_address, :inet.ip_address, integer}
  @type headers :: MapSet.t(String.t)
  @type proxies :: [cidr]
  @type clients :: [cidr]
  @type t :: %__MODULE__{headers: headers, proxies: proxies, clients: clients}

  defstruct [:headers, :proxies, :clients]
end
