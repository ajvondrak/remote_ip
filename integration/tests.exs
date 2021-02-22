defmodule Integration.Tests do
  @path Path.join(__DIR__, "tests")

  if IO.ANSI.enabled?() do
    @color "--color"
  else
    @color "--no-color"
  end

  def run do
    File.ls!(@path) |> Enum.map(&run/1) |> summarize()
  end

  def run(app) do
    IO.puts("---> Running integration tests on #{app} app")

    with 0 <- mix(app, "deps.clean", ["--build", "remote_ip"]),
         0 <- mix(app, "deps.get"),
         0 <- mix(app, "test", [@color]) do
      {app, :pass}
    else
      _ -> {app, :fail}
    end
  end

  def mix(app, task, args \\ []) do
    cmd = [task | args]
    dir = Path.expand(app, @path)
    out = IO.binstream(:stdio, :line)

    IO.puts(["-->", "mix" | cmd] |> Enum.join(" "))
    {_, status} = System.cmd("mix", cmd, cd: dir, into: out)
    status
  end

  def summarize(results) do
    count(results)

    Enum.each(results, fn
      {app, :pass} -> passed(app)
      {app, :fail} -> failed(app)
    end)
  end

  def count(results) do
    tests = length(results)
    fails = Enum.count(results, fn {_, flag} -> flag == :fail end)
    msg = [plural(tests, "integration test"), ", ", plural(fails, "failure")]

    IO.puts("")

    if fails > 0 do
      IO.ANSI.format([:red | msg]) |> IO.puts()
    else
      IO.ANSI.format([:green | msg]) |> IO.puts()
    end
  end

  def plural(1, string), do: "1 #{string}"
  def plural(n, string), do: "#{n} #{string}s"

  def passed(app) do
    IO.ANSI.format([:green, "  ✓ #{app}"]) |> IO.puts()
  end

  def failed(app) do
    IO.ANSI.format([:red, "  ✗ #{app}"]) |> IO.puts()
    System.at_exit(fn _ -> exit({:shutdown, 1}) end)
  end
end

Integration.Tests.run()
