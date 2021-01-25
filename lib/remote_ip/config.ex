defmodule RemoteIp.Config do
  @moduledoc """
  The internal configuration used by `RemoteIp`.

  **This module is for internal use.** It defines a struct that holds the
  options parsed out of the keywords given to `RemoteIp.init/1`. Users should
  pass keywords into the `plug` macro (or into `RemoteIp.from/2`) as documented
  by `RemoteIp`. The struct then holds onto the preprocessed data to avoid
  reprocessing it in between `RemoteIp.call/2` calls.
  """

  @type cidr :: {:inet.ip_address, :inet.ip_address, integer}
  @type headers :: [String.t]
  @type proxies :: [cidr]
  @type clients :: [cidr]
  @type t :: %__MODULE__{headers: headers, proxies: proxies, clients: clients}

  defstruct [:headers, :proxies, :clients]
end
