defmodule RemoteIp.DebugTest do
  use ExUnit.Case, async: true
  import ExUnit.CaptureIO
  import ExUnit.CaptureLog
  require RemoteIp.Debug

  def eval(quoted) do
    Code.eval_quoted(quoted, [], __ENV__) |> elem(0)
  end

  describe "with debugging disabled" do
    setup do
      Application.put_env(:remote_ip, :debug, false)
    end

    test "log/3 gets compiled away" do
      quoted = quote(do: RemoteIp.Debug.log(:add, [2, 2], do: 2 + 2))
      assert Macro.expand_once(quoted, __ENV__) == quote(do: 2 + 2)
    end

    test "log/3 does not evaluate the inputs" do
      quoted = quote do
        RemoteIp.Debug.log(:io, [IO.puts("inputs")]) do
          IO.puts("output")
        end
      end
      assert capture_io(fn -> eval(quoted) end) == "output\n"
    end
  end

  describe "with debugging enabled" do
    setup do
      Application.put_env(:remote_ip, :debug, true)
    end

    test "log/3 generates a log message based on the id, inputs, and output" do
      quoted = quote(do: RemoteIp.Debug.log(:add, [2, 2], do: 2 + 2))
      logged = capture_log(fn -> eval(quoted) end)
      assert logged =~ "id: :add, inputs: [2, 2], output: 4"
    end

    test "log/3 returns the output" do
      quoted = quote(do: RemoteIp.Debug.log(:add, [2, 2], do: 2 + 2))
      assert eval(quoted) == 4
    end

    test "log/3 evaluates the inputs" do
      quoted = quote do
        RemoteIp.Debug.log(:io, [IO.puts("inputs")]) do
          IO.puts("output")
        end
      end
      assert capture_io(fn -> eval(quoted) end) =~ "inputs\n"
    end

    test "log/3 evaluates the inputs prior to the output" do
      quoted = quote do
        struct = %{field: :before}
        RemoteIp.Debug.log(:diff, [struct.field]) do
          struct = %{field: :after}
          struct.field
        end
      end
      logged = capture_log(fn -> eval(quoted) end)
      assert logged =~ "id: :diff, inputs: [:before], output: :after"
    end
  end
end
