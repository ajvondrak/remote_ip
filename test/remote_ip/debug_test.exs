defmodule RemoteIp.DebugTest do
  use ExUnit.Case, async: true
  import ExUnit.CaptureIO
  import ExUnit.CaptureLog
  use RemoteIp.Debug

  def eval(quoted) do
    ast = Macro.expand_once(quoted, __ENV__)
    {term, _} = Code.eval_quoted(ast, [], __ENV__)
    term
  end

  describe "with debugging disabled" do
    setup do
      Application.put_env(:remote_ip, :debug, false)
    end

    test "log/2 expands into just the block" do
      quoted = quote(do: RemoteIp.Debug.log("four", do: 2 + 2))
      assert Macro.expand_once(quoted, __ENV__) == quote(do: 2 + 2)
    end

    test "log/2 evaluates the block correctly" do
      quoted = quote(do: RemoteIp.Debug.log("four", do: 2 + 2))
      assert eval(quoted) == 4
    end

    test "log/2 evaluates the block only once" do
      quoted = quote do
        RemoteIp.Debug.log("io") do
          IO.puts("side effect")
        end
      end
      assert capture_io(fn -> eval(quoted) end) == "side effect\n"
    end

    test "log/2 won't generate any log messages" do
      quoted = quote(do: RemoteIp.Debug.log("four", do: 2 + 2))
      assert capture_log(fn -> eval(quoted) end) == ""
    end
  end

  describe "with debugging enabled" do
    setup do
      Application.put_env(:remote_ip, :debug, true)
    end

    test "log/2 evaluates the block only once" do
      quoted = quote do
        RemoteIp.Debug.log("io") do
          IO.puts("side effect")
        end
      end
      assert capture_io(fn -> eval(quoted) end) == "side effect\n"
    end

    test "log/2 generates a log message based on the block's return value" do
      quoted = quote(do: RemoteIp.Debug.log("four", do: 2 + 2))
      assert capture_log(fn -> eval(quoted) end) =~ "four: 4"
    end
  end
end
