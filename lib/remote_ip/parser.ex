defmodule RemoteIp.Parser do
  @moduledoc """
  Defines the interface for parsing headers into IP addresses.

  `RemoteIp.Headers.parse/1` dynamically dispatches to different parser modules
  depending on the name of the header. For example, the `"forwarded"` header is
  parsed by `RemoteIp.Parsers.Forwarded`, which implements this behaviour.
  """

  @typedoc """
  Any module that implements the `RemoteIp.Parser` behaviour.
  """

  @type t() :: module()

  @doc """
  Parses the specific header's value into a list of IP addresses.

  This callback should be error-safe. For instance, if the header's value is
  invalid, it should return an empty list.

  The actual work of converting an individual IP address string into the tuple
  type should typically be done using `:inet` functions such as
  `:inet.parse_strict_address/1`.

  Note that a header may also contain more than one IP address. The order of
  the list is important because it's interpreted as routing information.
  Conceptually, the leftmost IP is the source of the request (the client), the
  rightmost IP is the destination (your server), and anything in the middle
  lists the proxy hops in order. However, in reality, there may be bad actors
  or strange routing that makes this more complicated. It's the job of
  `RemoteIp` to sort that out. This callback should *only* be concerned with
  faithfully parsing the literal order given by the header.
  """

  @callback parse(header :: binary()) :: [:inet.ip_address()]
end
