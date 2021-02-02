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
end
