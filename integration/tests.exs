defmodule Integration.Tests do
  @path Path.join(__DIR__, "tests")

  if IO.ANSI.enabled? do
    @color "--color"
  else
    @color "--no-color"
  end

  def run do
    File.ls!(@path) |> Enum.each(&run/1)
  end

  def run(app) do
    IO.puts("---> Running integration tests on #{app} app")
    mix(app, "deps.clean", ["--build", "remote_ip"])
    mix(app, "deps.get")
    mix(app, "test", [@color])
  end

  def mix(app, task, args \\ []) do
    cmd = [task | args]
    dir = Path.expand(app, @path)
    out = IO.binstream(:stdio, :line)

    IO.puts(["-->", "mix" | cmd] |> Enum.join(" "))
    {_, status} = System.cmd("mix", cmd, cd: dir, into: out)

    if status != 0 do
      System.at_exit(fn _ -> exit({:shutdown, 1}) end)
    end
  end
end

Integration.Tests.run
